package Zeta::SSN;
use strict;
use warnings;

sub new {
    my ($class, $dbh, $seq_ctl) = @_;

    my $sth_sel = $dbh->prepare("select cur, min, max  from seq_ctl where key = ? with rs for update");
    return unless $sth_sel;
    
    my $sth_upd = $dbh->prepare("update seq_ctl set cur = ?, ts_c = current timestamp where key = ?");
    return unless $sth_upd;

    bless {
        dbh => $dbh,
        sel => $sth_sel,
        upd => $sth_upd,
    }, $class;
}


#
# 取下一个
#
sub next {
    my ($self, $key) = @_;
    $self->{sel}->execute($key);
    my ($id, $max) = $self->{sel}->fetchrow_array();

    my $new;
    if ($id == $max) {
        $new = $min;
    } else {
        $new = $id + 1;
    }
    $self->{upd}->execute($new, $key);
    $self->{dbh}->commit();
    return $id;
}

#
# $self->('yspz', 1000)
# [10, 5, 100000];
# [$id, $min, $max, $cache];
#
sub next_n {
    my ($self, $key, $n) = @_;
    $self->{sel}->execute($key);
    my ($id, $min, $max) = $self->{sel}->fetchrow_array();


    my $new = $id + $n;
    if ($new > $max) {
        $new = ($new - $max) + $min;
    }
    
    $self->{upd}->execute($new, $key);
    $self->{dbh}->commit();
    return [ $id, $min, $max, $n ];
}

#
# $self->next_cache([$id, $min, $max, $n]);
#
sub next_cache {
    my ($self, $cache) = @_;

    # cache的序列号用完了
    if ($cache->[3] == 0 ) {
        return;
    }

    my $id = $cache->[0];
    $cache->[0]++;   # id   ++
    $cache->[3]--;   # size -- 
    if ($cache->[0] > $max) {
        $cache->[0] = $min;
    }
    return $id;
}

1;

__END__
create table seq_ctl (
    key    char(8),
    cur    bigint,
    min    bigint,
    max    bigint
);

-- key   :  流水号类型
-- cur   :  当前可用流水号
-- max   :  最大流水号

