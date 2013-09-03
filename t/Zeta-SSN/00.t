use Zeta::SSN;
use DBI;
use Test::More;
use Test::Differences;

$ENV{DSN} = 'SQLite';
plan tests => 22;
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=./seq.db",
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
$dbh->do("delete from seq_ctl");
$dbh->do("insert into seq_ctl(key, cur, min, max) values('HUNCK', 1, 1, 5)");
$dbh->do("insert into seq_ctl(key, cur, min, max) values('CACHE', 1, 1, 10)");
my $zs = Zeta::SSN->new($dbh);

#
# 10
# 
ok( $zs->next('HUNCK') == 1);
ok( $zs->next('HUNCK') == 2);
ok( $zs->next('HUNCK') == 3);
ok( $zs->next('HUNCK') == 4);
ok( $zs->next('HUNCK') == 5);
ok( $zs->next('HUNCK') == 1);
ok( $zs->next('HUNCK') == 2);
ok( $zs->next('HUNCK') == 3);
ok( $zs->next('HUNCK') == 4);
ok( $zs->next('HUNCK') == 5);

#
# 12
#
my $cache;
$cache = $zs->next_n('CACHE', 6); eq_or_diff($cache, [1, 1, 10, 6], 'next_n获取cache');
$cache = $zs->next_n('CACHE', 6); eq_or_diff($cache, [7, 1, 10, 6], 'next_n获取cache');
$cache = $zs->next_n('CACHE', 6); eq_or_diff($cache, [3, 1, 10, 6], 'next_n获取cache');
$cache = $zs->next_n('CACHE', 6); eq_or_diff($cache, [9, 1, 10, 6], 'next_n获取cache');
ok( $zs->next_cache($cache) == 9);
ok( $zs->next_cache($cache) == 10);
ok( $zs->next_cache($cache) == 1);
ok( $zs->next_cache($cache) == 2);
ok( $zs->next_cache($cache) == 3);
ok( $zs->next_cache($cache) == 4);
ok( $zs->next_cache($cache) == undef);
$cache = $zs->next_n('CACHE', 6); eq_or_diff($cache, [5, 1, 10, 6], 'next_n获取cache');
done_testing();

__END__
