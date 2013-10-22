#!/usr/bin/perl
use strict;
use warnings;
use Zeta::Run;
use DBI;
use Carp;
use POE;
use JSON::XS;
use Zeta::Mailer;
use Zeta::Mailer::Simple;
use Time::HiRes qw/sleep/;

#
# monq => 
# host =>
# port =>
#
sub {
    my $args = { @_ };
    my $logger = zlogger;

    # 连接消息队列
    my $stp = zkernel->zstomp();
    while( my $frame = $stp->receive_frame) {
         my $msg = decode_json($frame->body); 
         #
         #  mode   => 
         #  to     =>
         #  cc     =>
         #  sub    =>
         #  body   =>
         #  attach => 
         #   
         my $m;
         if ($msg->{mode} =~ /simple/) {
              $m = Zeta::Mailer::Simple->new();
         }
         else {
              $m = Zeta::Mailer->new();
              for (@{$msg->{attach}}) {
                  unless( -f $_) {
                      warn "can file[$_] does not exists";
                  }
              }
         }

         $m->set_all(
             'from'   => "$ENV{XMAIL_USER}\@yeepay.com",
              %$msg,
         );
         $m->send();
         $stp->ack({ frame => $frame });
    }
};


