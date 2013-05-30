#!/usr/bin/perl

use Zeta::Run;
use Zeta::POE::HTTPD::JSON;
use POE;

Zeta::POE::HTTPD::JSON->spawn( 
     alias    => 'hj',
     port     => 8888, 
     callback =>  sub {
          return {
              msg  => 'hello world',
              time =>  `date +%H%M%S`,
          };
     },
     events => {
         on_data => sub {
             warn "@_";
         },
     },
);

POE::Session->create(
    inline_states => {
        _start => sub {
            sleep 1;
            $_[KERNEL]->post('hj', 'on_data', qw/a b c/);
        },
    }
);

$poe_kernel->run();
exit 0;

