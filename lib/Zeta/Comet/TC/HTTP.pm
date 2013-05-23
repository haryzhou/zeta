package Zeta::Comet::TC::HTTP;

use strict;
use warnings;

use base qw/Zeta::Comet::TC/;

use Data::Dump;
use POE;
use POE::Wheel::ReadWrite;
use POE::Filter::HTTP::Parser;
use HTTP::Request::Common;
use Time::HiRes qw/gettimeofday/;

#
# ¶¨ÖÆon_start
#
sub _on_start {

    my $class  = shift;
    my $heap   = shift;
    my $kernel = shift;
    my $args   = shift;
    $heap->{filter} = 'POE::Filter::HTTP::Parser';
    $heap->{fargs}  = [];

}

#
# 接收到服务器应答
#
sub _packet {

    my $class = shift;
    my $heap  = shift;
    my $res   = shift;

    my $data =  $res->content();
    my $len = length $data;
    if ($len > 0) {
        $heap->{logger}->debug("recv data\n  length : [$len]");
        $heap->{logger}->debug_hex($data);
    }
    else {
        $heap->{logger}->debug("recv data\n  length : [0]");
    }
    return $data;

}

#
# 发送请求
#
sub _request {

    my $class = shift;
    my $heap  = shift;
    my $data  = shift;

    my $len = length $data;
    if ($len > 0) {
        $heap->{logger}->debug("send data\n  length : [$len]");
        $heap->{logger}->debug_hex($data);
    }
    else {
        $heap->{logger}->debug("send data\n  length : [0]");
    }

    my $config = $heap->{config};
    my $url = "http://$config->{remoteaddr}:$config->{remoteport}" . $data->{path};
    my $request = POST $url, Content => $data->{packet};
    $heap->{logger}->debug( "send request:\n" . Data::Dump->dump($request) );
    return $request;
}

1;

