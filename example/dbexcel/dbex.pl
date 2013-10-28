#!/usr/bin/perl
use Zeta::DB::Excel;
use DBI;

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=dbex.db",
    "",
    "",
    {
        RaiseError       => 1,
        PrintError       => 0,
        AutoCommit       => 0,
        FetchHashKeyName => 'NAME_lc',
        ChopBlanks       => 1,
        InactiveDestroy  => 1,
    },
);

my $dbex = Zeta::DB::Excel->new(dbh => $dbh);

$dbex->excel(
    filename => './dbex.xls',
    sheet => {
        '分润1' => {
            hmap   => { f1 => '交易金额',  f2 => '扣率',  f3 => '手续费',  f4 => '分润' },
            select => "select * from dbex",
            flist  => [qw/f2 f1 f4 f3/],
            sum    => [qw/f1 f4/],
            filter => \&filter,
        },

        '分润2' => {
            hmap   => { f1 => '交易金额',  f2 => '扣率',  f3 => '手续费',  f4 => '分润' },
            select => "select * from dbex",
            flist  => [qw/f2 f1 f4 f3/],
            sum    => [qw/f1 f4/],
            filter => \&filter,
        },
    },
);

sub filter {
    my $row = shift;
    for (keys %$row) {
        $row->{$_} *= 2;
    }
    return 1;
}


__END__
