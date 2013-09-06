#######################################################################
#  Zeta::FLoad.pm
#      从文件读取记录, 处理生成记录， 插入表的基本框架
#
#     xls_row    :  load_xls时的可选钩子
#     pre        :  load时的行预处理 返回undefined 则不处理次行
#     rsplit     :  load时行的分割处理， load_xls时为数组引用, 或是返回数组引用的函数
#     rhandle    :  分割后的字段调整处理
#     dbh        :  数据库连接
#     table      :  插入那张表
#     field      :  哪些字段
#     exclusive  :  插入除exclusive字段意外的所有其他字段
#     batch      :  提交批次的大小
#     logger     :  日志对象
#
#  Created by zhou chao on 2013-09-05.
#  Copyright 2013 zhou chao. All rights reserved.
#######################################################################
package Zeta::FLoad;
use strict;
use warnings;
use IO::File;
use Time::HiRes qw/gettimeofday tv_interval/;
use Spreadsheet::ParseExcel;


# ===================================================================
# my $load = ZSTL::Load->new(
#    dbh      => $dbh, 
#    table    => 'table_name',
#    field    => [qw/fld1 fld2 fld3 .../], 
#
#    xls_row  => \&xls_row,   # 如果是xls文件, xls获取row的函数, 可选
#
#    pre      => \&pre,       # 预处理, 可选, xls文件不需要此项目
#    rsplit   => \&rsplit,    # 分割处理
#    rhandle  => \&rhandle,   # 分割后处理
#
#    batch    => 100,         # 批次大小
# ) 
# $load->load($file);
# $load->load_xls($file, 0, 1);
# ===================================================================
sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    
    my @fld = @{$self->{field}} if $self->{fleld} and @{$self->{field}};
    unless(@fld) {
        @fld =  @{$self->flist()};
    }
    return unless @fld;
    my $fldstr = join ', ', @fld;
    
    my $markstr = join ' ,',  ('?') x @fld;
    my $sql     = "insert into $self->{table} ($fldstr) values($markstr)"; # warn "[$sql]";
    my $sth     = $self->{dbh}->prepare($sql) or die "can not prepare[$sql]";
    $self->{sth} = $sth;
    
    $self->{batch} ||= 300;
    
    return $self;
}

###########################################################
#  $self->flist();
#    获取表的插入字段: 按定义顺序
###########################################################
sub flist {
    my $self = shift;
    my $table = $self->{table};
    my $exclusive = $self->{execlusive};
    
    my $sth = $self->{dbh}->prepare("select* from $table");
    my $nhash = $sth->{NAME_lc_hash};
    delete @{$nhash}{@{$self->{execlusive}}} if $exclusive and @$exclusive;
    
    my %rhash = reverse %$nhash;
    my @fld = @rhash{sort { $a <=> $b } keys %rhash};
    
    return \@fld;
}

###########################################################
# $self->load($file);
#    加载文件
###########################################################
sub load {
    my $self = shift;
    my $file = shift;
    my $fh = IO::File->new("<$file");
    
    my $batch = 0;
    my $cnt = 0;
    my $ts_beg = [gettimeofday];
    my $elapse;
   
    my $pre = $self->{pre}; 
    while(<$fh>) {
       
        if ($pre) { 
            next unless $_ = $pre->($_);      # 预处理
        }
        my $fld = $self->{rsplit}->($_);      # 分割处理
        my $row = $self->{rhandle}->($fld);  # 分割后处理
        # warn "execute[@$row]";
        $self->{sth}->execute(@$row);
        $cnt++;
        if ($cnt == $self->{batch}) {
            $self->{dbh}->commit();
            $batch++;
            $cnt = 0;
            $elapse = tv_interval($ts_beg);
            $self->{logger}->info("batch[$batch] cnt[$cnt] elapse[elapse]") if $self->{logger};
        }
    }
    
    if ($cnt) {
        $batch++;
        $cnt = 0;
        $elapse = tv_interval($ts_beg);
        $self->{logger}->info("batch[$batch] cnt[$cnt] elaspe[elapse] last batch!!!") if $self->{logger};
    }
 
    return $self;
}

###########################################################
# $load->load_xls($file, $sheet, $rmin)
#    加载xls文件
###########################################################
sub load_xls {
    my $self  = shift;
    my $file  = shift;
    my $shidx = shift;
    my $rmin  = shift;
    
    my $parser = Spreadsheet::ParseExcel->new();
    my $wb     = $parser->parse($file);
    my $sheet  = $wb->worksheet($shidx);
    my $rmax   = ($sheet->row_range())[1];
    
    my $cidx;
    if ('ARRAY' eq ref $self->{rsplit}) {
        $cidx = $self->{rsplit};
    }
    elsif('CODE' eq ref $self->{rsplit}) {
        $cidx = $self->{rsplit}->();
    }
    unless($cidx && 'ARRAY' eq ref $cidx && @$cidx ) {
        die "load_xls need rsplit [] or subroutine return []";
    }
        
    my $xls_row = $self->{xls_row};
    if ($xls_row && "CODE" ne ref $xls_row) {
        die "xls_row must be code ref";
    }
    
    $xls_row ||= \&xls_row;
    
    my $ts_beg = [gettimeofday];
    my $elapse;
    my $batch = 0;
    my $cnt = 0;
    for my $ridx ($rmin .. $rmax) {
        my $fld = $xls_row->($sheet, $ridx, $cidx);
        my $row = $self->{rhandle}->($fld);
        $self->{sth}->execute(@$row);
        $cnt++;
        if ($cnt == $self->{batch}) {
            $self->{dbh}->commit();
            $batch++;
            $cnt = 0;
            $elapse = tv_interval($ts_beg);
            $self->{logger}->info("batch[$batch] cnt[$cnt] elapse[elapse]") if $self->{logger};
        }
    }
    
    if ($cnt) {
        $batch++;
        $cnt = 0;
        $elapse = tv_interval($ts_beg);
        $self->{logger}->info("batch[$batch] cnt[$cnt] elaspe[elapse] last batch!!!") if $self->{logger};
    }
 
    return $self;
}

###########################################################
# &xls_row($sheet,$ridx, [qw/cidx1 cidx2 .../]);
#    默认的获取xls行的函数
###########################################################
sub xls_row {
    my $sheet = shift;
    my ($ridx, $cidx) = @_;
    my @row;
    for (@$cidx) {
        my $cell = $sheet->get_cell($ridx, $_);
        unless ($cell) {
            push @row, undef;
            next;
        }
        my $val = $cell->value();
        # warn "cell($ridx, $_) = $val";
        push @row, $val;
    }
    return \@row;
}

1;

