use Carp;
sub {
    my $sync = shift;
    my $dbh = $sync->{dst}{dbh};
    my $qsql_mcht = "select mname from mcht_inf where mid = ?";
    my $sth = $dbh->prepare($qsql_mcht);
    unless($sth) {
        confess "can not prepare[$qsql_mcht]";
    }
    return {
        sth_mcht => $sth,
    };
};

