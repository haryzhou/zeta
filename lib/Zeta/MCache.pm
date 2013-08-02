package Zeta::MCache;
use strict;
use warnings;

my %mcache;
my %mlru;
my %size;

#
#  Zeta::MCache->new( t => 10, T => 10 )
#
sub new {
    my $class = shift;
    bless {
        mcache => {},
        mlr    => {},
        size   => { @_ },
    }, $class;
}

#
# $mc->size(t => 10);
# $mc->size('t');
#
sub size {
    if (@_ == 3) {
       shift->{size}{+shift} = shift;
    }
    elsif (@_ == 2) {
       return shift->{size}{+shift};
    }
}

# Zeta::MCache->get('type', 'key');
sub get {
    my $self = shift;;
    my ($t, $k) = @_;

    $self->{mlru}{$t}   ||= [];
    $self->{mcache}{$t} ||= {};
   
    return $self->{mcache}{$t}{$k};
}

#  Zeta::MCache->set('type', 'key', 'value');
sub set {
    my $self = shift;
    my ($t, $k, $v) = @_;
    $self->{mcache}{$t}{$k} = $v;
    push @{ $self->{mlru}{$t} }, $k;

    delete $self->{mcache}{$t}{shift @{$self->{mlru}{$t}}} 
        if @{$self->{mlru}{$t}} > $self->{size}{$t}; 
}

1;
