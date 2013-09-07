use Zeta::FLoad;
use DBI;
use Test::More;
use Test::Differences;

plan tests => 2;

$ENV{DSN} = 'SQLite';
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=./fload.db",
    "",
    "",
    {
        RaiseError       => 1,
        PrintError       => 0,
        AutoCommit       => 0,
        FetchHashKeyName => 'NAME_lc',
        ChopBlanks       => 1,
        InactiveDestroy  => 1,
        sqlite_unicode   => 1,
    },
);

$dbh->do("delete from fload");
$dbh->commit();
Zeta::FLoad->new(
    dbh       => $dbh,
    table     => 'fload',
    exclusive => [],

    pre       => \&fload_pre,
    rsplit    => \&fload_split,
    rhandle   => \&fload_handle,
    batch     => 2,
)->load("./fload.dat");

my $sth = $dbh->prepare("select count(*) from fload");
$sth->execute();
my ($cnt) = $sth->fetchrow_array();

ok( $cnt == 8 );

Zeta::FLoad->new(
    dbh       => $dbh,
    table     => 'fload',
    exclusive => [],

    pre       => \&fload_pre,
    rsplit    => [ 0..3 ],
    rhandle   => \&fload_handle,
    batch     => 2,
)->load_xls("./fload.xls", 0, 0);

$sth = $dbh->prepare("select count(*) from fload");
$sth->execute();
my ($cnt) = $sth->fetchrow_array();

ok( $cnt == 16 );

sub fload_pre {
    my $line = shift;
    $line =~ s/^\s+//g;
    $line =~ s/\s+$//g;
    return $line; 
}

sub fload_split {
    [ split ',', +shift ];
}

sub fload_handle {
    [ reverse @{+shift} ];
}

