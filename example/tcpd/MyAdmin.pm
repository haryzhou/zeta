package MyAdmin;

sub new {
   bless {}, shift;
}

sub handle {
    my $self = shift;
    return {
       count => $self->{count}++,
    };
}

1;

