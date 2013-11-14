package Zeta::POE::Client::XML;
use strict;
use warnings;
use base qw/Zeta::POE::Client/;
use XML::Simple;
use Encode;
use Data::Dumper;

#
# charset  => 'utf8',
# RootName => 'NoRoot',
#
sub spawn {
    my $class = shift;
    my $args = { @_ };
    $args->{charset} ||= 'utf8';
    $args->{RootName} ||= 'NoRoot';
    $class->_spawn(%$args);
}

#
# 
#
sub _in {
    my ($class, $args, $in) = @_;
    unless($args->{charset} eq 'utf8') {
        # warn "begin decode('gbk', [$in])";
        $in = encode('utf8', decode($args->{charset}, $in));
        # warn "got now[$in]";
    }
    # warn "begin XMLin($in)";
    return XMLin($in);
}

#
#
#
sub _out {
    my ($class, $args, $out) = @_;
    # warn "begin XMLout(" . Dumper($out) . ")";
    my $res = XMLout($out, NoAttr => 1, RootName => $args->{RootName});
    unless($args->{charset} eq 'utf8') {
        # warn "begin encode($args->{charset}, [$res])...";
        $res = encode($args->{charset}, decode('utf8', $res));
    }
    return $res;
}

1;

__END__
=head1 NAME


=head1 SYNOPSIS


=head1 API


=head1 Author & Copyright


=cut


