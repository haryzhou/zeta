package Zeta::Encode;

use strict;
use warnings;
use base qw/Exporter/;
use POSIX qw/isxdigit/;

our @EXPORT = qw/
  bcd2num
  num2bcd
  bin2num
  num2bin
/;

############################################
# \x12\x13  =>  "1234"
############################################
sub bcd2num {
    my $num = unpack( "H*", shift );
    $num =~ s/^0+//g;
    return $num;
}

############################################
#  右靠左补0
# "123"  => "\x01\x23";
############################################
sub num2bcd {
    my $num = shift;
    my $len = length $num;
    if ( $len % 2 ) {
        $num = "0$num";
    }
    return pack( "H*", $num );
}

############################################
# 8   => \x08
# 16  => \x10
# 24  => \x18
############################################
sub num2bin {
    my $num = shift;
    my @data;
    use integer;
    while (1) {
        my $res = $num % 16;
        if ( $res > 9 ) {
            $res = chr( ord('A') + $res - 10 );
        }
        unshift @data, $res;
        $num int($num/16);
        last if $num == 0;
    }
    my $str = join '', @data;
    if ( ( length $str ) % 2 ) {
        $str = "0$str";
    }
    return pack( "H*", $str );
}

############################################
# "\x08"  => 8
# "\x10"  => 16
# "\x18   => 24
############################################
sub bin2num {
    my $bin   = shift;
    my @digit = split '', uc unpack( "H*", $bin );
    my $num   = 0;
    my $base  = 1;

    my $a = ord('A');
    for ( reverse @digit ) {
        if ( $_ =~ /[A-F]/ ) {
            $_ = 10 + ord($_) - $a;
        }
        $num += $_ * $base;
        $base *= 16;
    }
    return $num;
}

1;

__END__

=head1 NAME

  Zeta::Encode  - a simple module for encode && decode between bcd/bin/num

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;

  use Zeta::Encode;

=head1 API

  bin2num:
  num2bin:
  num2bcd:
  bcd2num:

=head1 Author & Copyright

  zcman2005@gmail.com

=cut


