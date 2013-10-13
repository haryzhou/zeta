#!/usr/bin/perl
use strict;
use warnings;
use Zeta::DBTran;
use Zeta::Log;
use DBI;

my $logger = Zeta::Log->new(
    logurl => 'stderr',
    loglevel => 'DEBUG',
);
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=dbtran.db",
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

my $dbtran = Zeta::DBTran->new(
    logger => $logger,
    dbh    => $dbh,
);

$dbtran->tran(
    tbl_test => [
        "new.sql",
        sub {
            my $row = shift;
            my ($a, $b) = @{$row}{qw/a b/};
            return [ $a, $b, $a + $b ];
        }
    ]
);
