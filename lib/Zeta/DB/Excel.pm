package Zeta::DB::Excel;
use strict;
use warnings;
use Carp;
use Spreadsheet::WriteExcel;
use Data::Dumper;
use Encode;

#
# Zeta::DB::Excel->new( dbh => $dbh);
#
sub new {
    my $class = shift;
    bless { @_ }, $class;
}

#
#  filename => '/tmp/xxx.xls',
#  sheet => {
#      分润明细 => {
#          hmap   => {  fld1  => '姓名',  .... }, # 表头映射, 每个域的中文名称
#          select => "select * from xxxx",        # select 语句
#          flist  => [ qw/fld3 fld2 fld1/ ],      # 域排列顺序
#          sum    => [ qw/fld2 fld1/ ],           # 哪些域需要汇总
#          filter => \&filter,                    # 行过滤, 如有的域需要decode('utf8', $fld);
#      },
#      sheet1 => {}
#  }
#
sub excel {
    my $self = shift;
    my $args = { @_ };


    # excel文件
    my $book  = Spreadsheet::WriteExcel->new($args->{filename});
    my $hfmt  = $book->add_format(border => 1, bg_color => 'gray');
    my $rfmt  = $book->add_format(border => 1);
    $self->{book} = $book;
    $self->{hfmt} = $hfmt;
    $self->{rfmt} = $rfmt;

    for my $name (keys %{$args->{sheet}}) {
        $self->add_worksheet(decode('utf8', $name), $args->{sheet}->{$name});
    }
    $book->close();

}

#
#
#
sub add_worksheet {

    my ($self, $name, $args) = @_;
    my $sheet = $self->{book}->add_worksheet($name);
    my $hfmt  = $self->{hfmt};
    my $rfmt  = $self->{rfmt};

    # sql语句准备
    my $sth = $self->{dbh}->prepare($args->{select});
    unless($sth) {
        warn "can not prepare[$args->{select}]";
        return;
    }
    my $line = 1;  # 当前行

    # 写入表头, 按flist描述的顺序写入表头
    my @head = map { decode('utf8', $_) } @{$args->{hmap}}{@{$args->{flist}}};
    $sheet->write('A1', \@head, $hfmt);
    $line++;
   
    # 写入数据行 
    $sth->execute();
    while(my $row = $sth->fetchrow_hashref()){
        # warn "got row: " . Dumper($row);
        # 数据行过滤处理
        if ($args->{filter}) {
            unless($args->{filter}->($row)) {
                confess "can not filter line: " . Dumper($row);
            }
        }
        my @flds = @{$row}{@{$args->{flist}}}; 
        $sheet->write("A$line", \@flds, $rfmt);
        $line++;
        # for (@{$args->{sum}}) {
        #    $sum->{$_} += $row->{$_};
        # }
    }
    # warn Dumper($sum);
  
    # 合计部分
    if ($args->{sum}) {
        my $end = $line - 1;
        my %sum = map { $_ => undef } @{$args->{flist}};
        for (@{$args->{sum}}) {
            my $idx = $self->index($args->{flist}, $_);
            $sum{$_} = "=SUM(${idx}2:${idx}$end)";
        }
        my @sum = @sum{@{$args->{flist}}};
        $sum[0] = decode('utf8', '合计');
        print Dumper(\@sum);
        $sheet->write("A$line", \@sum, $hfmt);
    }

    return $self;
}

#
#
#
#
sub index {
    my $self = shift;
    my ($flist, $fld) = @_;
    # warn "index called with: " . Dumper(\@_);
    my $idx = 0;
    for (@$flist) {
        if ($fld eq $_) {
            return &_index($idx);
        }
        $idx++;
    }
}

#  Excel的列index计算
sub _index {
    my $idx = shift;
    warn "calc _index($idx)";
    my @data;
    while(1) {
        my $res = $idx % 26;
        unshift @data, chr(ord('A')+$res); 
        $idx = int($idx/26);
        warn "idx now[$idx]";
        last if $idx == 0;
    } 
    return join '', @data;
}

1;

