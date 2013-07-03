#!/usr/bin/perl

#
# 如果遇到不能auth的情况
# 需要安装
#     Authen::SASL
#
#

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

