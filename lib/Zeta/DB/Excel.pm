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
#  hmap   => {  fld1  => '姓名',  .... }, # 表头映射, 每个域的中文名称
#  select => "select * from xxxx",        # select 语句
#  flist  => [ qw/fld3 fld2 fld1/ ],      # 域排列顺序
#  sum    => [ qw/fld2 fld1/ ],           # 哪些域需要汇总
#  fname  => '/tmp/xxx.xls',              # 文件名称
#  filter => \&filter,                    # 行过滤, 如有的域需要decode('utf8', $fld);
#
sub excel {
    my $self = shift;
    my $args = { @_ };

    # excel文件
    my $book  = Spreadsheet::WriteExcel->new($args->{fname});
    my $sheet = $book->add_worksheet();
    my $hfmt  = $book->add_format(border => 1, bg_color => 'gray');
    my $rfmt  = $book->add_format(border => 1);

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
    my $sum;
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
        for (@{$args->{sum}}) {
            $sum->{$_} += $row->{$_};
        }
    }
    # warn Dumper($sum);
  
    # 合计部分
    if ($args->{sum}) {
        my @sum = @{$sum}{@{$args->{flist}}};
        # warn Dumper(\@sum);
        $sum[0] = decode('utf8', '合计');
        $sheet->write("A$line", \@sum, $hfmt);
    }

    $book->close();
}

1;

