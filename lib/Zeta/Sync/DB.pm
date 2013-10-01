package Zeta::Sync::DB;
use strict;
use warnings;
use Carp;
use Time::HiRes qw/gettimeofday tv_interval/;
use DBI;

#---------------------------------------------------------
# 只支持
#       sqlite 
#       mysql
#       db2
#       oracle
#---------------------------------------------------------
# drop table sync_ctl;
# create table sync_ctl (
#     stable       char(32)       not null,
#     kfld_src     varchar(2048)  not null,
#     vfld_src     varchar(2048)  not null,
#     tfld_src     char(32)       not null,
# 
#     dtable       char(32)       not null,
#     kfld_dst     varchar(2048)  not null,
#     vfld_dst     varchar(2048)  not null,
#     ufld_dst     varchar(2048)  not null,
#     tfld_dst     char(32)       not null,
#  
#     convert      varchar(128), 
# 
#     interval    int            not null,
#     gap         int            not null,
#     last        timestamp      not null,
#
#     ts_c  timestamp  default current_timestamp,
#     ts_u  timestamp
# );
#---------------------------------------------------------
# my $dbs = Zeta::Sync::DB->new(
#     logger => $logger,
#     src => {
#        dsn     => 'dbi:DB2:zdb',
#        user    => 'ypinst', 
#        pass    => 'ypinst', 
#     },
#     dst => {
#        dsn    => 'dbi:Oracle:host=foobar;sid=DB;port=1521',
#        user   => 'ypinst', 
#        pass   => 'ypinst', 
#        schema => 'zstl',
#     },
# );
# $dbs->sync('txn_log');
#---------------------------------------------------------
sub new {
    my $class = shift;
    my $args = { @_ };
    my $logger = $args->{logger};
 
    my $src = &_init_src($args->{src});
    my $dst = &_init_dst($args->{dst});

    # 构建对象
    my $self = bless {
        logger => $args->{logger},
        src    => $src,
        dst    => $dst,
    }, $class;

    return $self;
}

#
# 与数据库类型相关的时间戳获取
#
sub timestamp_dbd {
    my ($self, $ctl) = @_;

    # 更新sync_ctl控制记录
    my $sql_qts;
    my $sql_uctl;
    if ($self->{src}{type} eq 'db2') {
        $sql_qts  = "values current timestamp - $ctl->{gap} seconds";
        $sql_uctl = q/update sync_ctl set last = ?, ts_u = current timestamp where stable = ?/;
    }
    elsif ($self->{src}{type} eq 'oracle') {
        $sql_qts = "select current timestamp - $ctl->{gap}/24/60/60 from dual";
        $sql_uctl = q/update sync_ctl set last = ?, ts_u = current timestamp where stable = ?/;
    }
    elsif ($self->{src}{type} eq 'sqlite') {
        $sql_qts = "select datetime('now', '-$ctl->{gap} second')"; 
        $sql_uctl = q/update sync_ctl set last = ?, ts_u = current_timestamp where stable = ?/;
    }
    elsif ($self->{src}{type} eq 'mysql') {
    }
    else {
        confess "internal error";
    }
    my $qts  = $self->{src}{dbh}->prepare($sql_qts)  or confess "can not prepare[$sql_qts]";
    my $uctl = $self->{src}{dbh}->prepare($sql_uctl) or confess "can not prepare[$sql_uctl]";  
    return ($qts, $uctl);
}


#----------------------------------------------------------
# $sync->run($src_table);
#----------------------------------------------------------
sub sync {
    my ($self, $stbl) = @_;

    my $logger = $self->{logger};

    # 源数据库   
    my $sdb  = $self->{src}{dbh};

    # 查询控制记录
    my $sql_qctl = q/select * from sync_ctl where stable = ?/;
    my $qctl = $sdb->prepare($sql_qctl) or confess "can not prepare[$sql_qctl]";  # 查询控制表
    $qctl->execute($stbl);
    my $ctl = $qctl->fetchrow_hashref();
    unless($ctl) {
        confess "can not find sync_ctl with table[$stbl]";
    }
    $qctl->finish();
    my ($qts, $uctl) = $self->timestamp_dbd($ctl);  # 获取qts uctl

    # 查询源表记录语句
    my ($kfld_src, $vfld_src, $tfld_src)  = @{$ctl}{qw/kfld_src vfld_src tfld_src/};
    my @kfld_src = split ',', $kfld_src;
    my @vfld_src = split ',', $vfld_src;
    my $qfldstr  = join(', ', @kfld_src, @vfld_src, $tfld_src);
    my $sql_qsrc = "select $qfldstr from $stbl where $tfld_src >= ? and $tfld_src < ?"; # warn $sql_qsrc;
    my $qsrc = $sdb->prepare($sql_qsrc) or confess "can not prepare[$sql_qsrc]";

    # 目标数据库
    my $ddb = $self->{dst}{dbh};
    my ($dtbl, $kfld_dst, $vfld_dst, $ufld_dst, $tfld_dst) = @{$ctl}{qw/dtable kfld_dst vfld_dst ufld_dst tfld_dst/};
    my @kfld_dst = split ',', $kfld_dst;
    my @vfld_dst = split ',', $vfld_dst;
    my @ufld_dst = split ',', $ufld_dst;
    my $knum = @kfld_dst;  # 主键字段个数
    my $vnum = @vfld_dst;  # 更新值字段个数
    my $unum = @ufld_dst;

    # 插入目标表语句
    my $ifldstr  = join(', ', @kfld_dst, @vfld_dst, $tfld_dst);
    my $markstr  = join(', ', ('?') x ($knum + $vnum + 1));
    my $sql_idst = "insert into $dtbl ($ifldstr) values($markstr)";  warn "$sql_idst";
    my $idst = $ddb->prepare($sql_idst) or confess "can not prepare[$sql_idst]";

    # 更新语句
    my $setstr   = join(', ', map { "$_ = ?" } (@ufld_dst, $tfld_dst));
    my $condstr  = join(' and ', map { "$_ = ?" } @kfld_dst);
    my $sql_udst = "update $dtbl set $setstr where $condstr";   warn "$sql_udst";
    my $udst = $ddb->prepare($sql_udst) or confess "can not prepare[$sql_udst]";
    
    # 转换器, 负责将$slog转换为$dlog
    my $convert;
    unless( -f $ctl->{convert}) {
        confess "convert config[$ctl->{convert}] does not exist";
    }
    $convert = do $ctl->{convert};
    if ($@) {
        confess "can not do file[$ctl->{convert}] error[$@]";
    }
    my $uconv = $convert->{update};
    my $iconv = $convert->{insert};

    # 数据库类型
    my $unique;
    if ($self->{dst}{type} eq 'db2') {
        $unique = 'SQL0803N';
    }
    elsif ($self->{dst}{type} eq 'oracle') {
        $unique = '0803';
    }
    else {
        confess "internal error";
    }

    # 重新设置qctl
    $sql_qctl = q/select interval, gap, last from sync_ctl where stable = ?/;
    $qctl = $sdb->prepare($sql_qctl) or confess "can not prepare[$sql_qctl]";
    while(1) {

        my $ucnt = 0;
        my $icnt = 0;

        my $ts_beg = [ gettimeofday ];

        # 取控制记录
        $qctl->execute($stbl);
        $ctl = $qctl->fetchrow_hashref();

        # 获取上次开始时间, 到本次结束时间(当前时间的前gap秒)
        $qts->execute();
        my ($end) = $qts->fetchrow_array();
        my $beg = $ctl->{last};

        # 开始一轮sync
        $qsrc->execute($beg, $end);
        while(my $slog = $qsrc->fetchrow_arrayref()) {
          
            # 插入目标库表
            my $dlog = $iconv->($self, $slog);
            eval {
                $idst->execute(@$dlog);
            };
            if ($@) {
                # 主键重复
                if ($@ =~ /$unique/) {
                    $dlog = $uconv->($self, $slog);
                    $udst->execute(@$dlog); 
                    $ucnt++;
                }
                else {
                    confess "system error[$@]";
                }
            }
            else {
                $icnt++;
            }
        }
        $ddb->commit();   # 目的数据库提交

        $uctl->execute($end, $stbl);
        $sdb->commit();  # 更新控制记录表

        my $elapse = tv_interval($ts_beg);
        $logger->info(sprintf("update[%04d] insert[%04d] elapse[$elapse]", $ucnt, $icnt));
        sleep $ctl->{interval};
    }
}

#-------------------------------
# 源数据库初始化
#-------------------------------
sub _init_src {
    my $src = shift;

    my $dbh = DBI->connect(@{$src}{qw/dsn user pass/}, {
        RaiseError       => 1,
        PrintError       => 0,
        AutoCommit       => 0,
        FetchHashKeyName => 'NAME_lc',
        ChopBlanks       => 1,
        InactiveDestroy  => 1,
    });
    unless($dbh) {
        confess "can not connect[$src->{dsn}]";
    }

    
    my $stype;
    # db2
    if ($src->{dsn} =~ /DB2/) {
        $stype = 'db2';
        if ($src->{schema}) {
            $dbh->do("set current schema $src->{schema}");
            $dbh->commit();
        }
    }
    # oracle
    elsif($src->{dsn} =~ /Oracle/) {
        $stype = 'oracle';
    }
    # mysql
    elsif($src->{dsn} =~ /mysql/) {
        $stype = 'mysql';
    }
    # sqlite
    elsif($src->{dsn} =~ /SQLite/) {
        $stype = 'sqlite';
    }
    else {
        confess "不支持的数据库类型";
    }

    return {
        type => $stype,
        dbh  => $dbh,
    };
}

#-------------------------------
# 源数据库初始化
#-------------------------------
sub _init_dst {

    my $dst = shift;

    # 连接数据库
    my $dbh = DBI->connect(@{$dst}{qw/dsn user pass/}, {
        RaiseError       => 1,
        PrintError       => 0,
        AutoCommit       => 0,
        FetchHashKeyName => 'NAME_lc',
        ChopBlanks       => 1,
        InactiveDestroy  => 1,
    });
    unless($dbh) {
        confess "can not connect[$dst->{dsn}]";
    }
    my $dtype;

    # db2
    if ($dst->{dsn} =~ /DB2/) {
       $dtype = 'db2';
       if ($dst->{schema}) {
           $dbh->do("set current schema $dst->{schema}");
           $dbh->commit();
       }
    }
    # oracle
    elsif($dst->{dsn} =~ /Oracle/) {
       $dtype = 'oracle';
    }
    # mysql
    elsif($dst->{dsn} =~ /mysql/) {
        $dtype = 'mysql';
    }
    # sqlite
    elsif($dst->{dsn} =~ /SQLite/) {
        $dtype = 'sqlite';
    }
    # 不支持
    else {
        confess "不支持的数据库类型";
    }

    return {
        dbh  => $dbh,
        type => $dtype, 
    };
}


1;
