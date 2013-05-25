#!/usr/bin/perl
use Zeta::POE::TCPD::JSON;
use POE;

Zeta::POE::TCPD::JSON->spawn( 
     port     => 8888, 
     codec    => 'ascii 4',
     callback => sub {  { now => `date +%H%M%S` } },
);
$poe_kernel->run();
exit 0;

