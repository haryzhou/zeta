package Zeta::POE::XMLD;
use strict;
use warnings;
use base qw/Zeta::POE::TCPD/;
use Encode;
use XML::Simple;
use Data::Dumper;

#
#  lfd     => $lfd,
#  port    => '9999',
#  codec   => 'xxxx'
#  module  => 'MyModule',
#  para    => 'para',
#
#  charset  => 'gbk/utf8',
#  RootName =>
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
    
    unless($args->{charset} eq 'utf8' ) {
        $in = encode('utf8', decode($args->{charset},$in));
    }
    return XMLin($in);
}

#
#
#
sub _out {
    my ($class, $args, $out) = @_;
    
    # 
    # warn "begin XMLout(" . Dumper($out) . ")";
    my $res = XMLout($out, NoAttr => 1, RootName => $args->{RootName});
    
    # warn "kkkkkkkkkkkkkkkkkkkout[$res]";
    unless($args->{charset} eq 'utf8' ) {
        # $res = encode($args->{charset}, decode('utf8', $res));   #  如gbk编码
        $res = encode($args->{charset}, $res);   #  如gbk编码
        return $res;
    }
    else {
        return encode('utf8', $res);
    }
}

1;

__END__
=head1 NAME


=head1 SYNOPSIS


=head1 API


=head1 Author & Copyright


=cut


