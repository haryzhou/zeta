#!/usr/bin/perl


use Zeta::Mailer;

my $m = Zeta::Mailer->new( debug => 1,);

$m->set_all(
  'from'   => 'chao.zhou@yeepay.com',
  'to'     => [ 'hongbo.gan@yeepay.com' ],
  'sub'    => 'subject1',
  'body'   => 'body',
  'attach' => [ './Mailer.t' ],
);

$m->send();

