#!/usr/bin/perl
use Zeta::POE::TCP;
use POE;

Zeta::POE::TCP->spawn( 
     port     => 8888, 
     callback => sub { 'hello world'; },
     codec    => 'ascii 4',
);
$poe_kernel->run();
exit 0;

