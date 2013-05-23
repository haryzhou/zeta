#!/usr/bin/perl

use Zeta::Run;
use Zeta::POE::HTTPD;
use POE;

Zeta::POE::HTTPD->spawn( 
     port     => 8888, 
     callback =>  sub {
          return {
              msg  => 'hello world',
              time =>  `date +%H%M%S`,
          };
     },
);
$poe_kernel->run();
zkernel->process_stopall();
exit 0;

