package Zeta::Run::Main::HTTP;

use Zeta::Run;
use POE;
use Carp;
use HTTP::Request;
use HTTP::Response;
use POE::Wheel::ListenAccept;
use POE::Filter::HTTPD;
use POE::Wheel::ReadWrite;
use JSON::XS;

#
# (
#    ip      => '192.168.1.10',
#    port    => '9999',
#    module => 'XXX::Admin',
#    para    => 'xxx.cfg',
# )
#
sub run {
    my $class = shift;
    my $args  = {@_};

    confess "port needed" unless $args->{port};
    confess "module needed" unless $args->{module};

    # 加载管理模块
    eval "use $args->{module};";
    confess "can not load module[$args->{module}] error[$@]" if $@;

    # 构造管理对象
    my $admin = $args->{module}->new( $args->{para} ) or confess "can not new $args->{module} with " . Data::Dump->dump( $args->{para} );

    # 创建poe
    POE::Session->create(
        inline_states => {
            _start => sub {
                $_[HEAP]{la} = POE::Wheel::ListenAccept->new(
                    Handle => IO::Socket::INET->new(
                        LocalPort => $args->{port},
                        Listen    => 5,
                    ),
                    AcceptEvent => "on_client_accept",
                    ErrorEvent  => "on_server_error",
                );
            },

            # 收到连接请求
            on_client_accept => sub {
                my $cli = $_[ARG0];
                my $w   = POE::Wheel::ReadWrite->new(
                    Handle       => $cli,
                    InputEvent   => "on_client_input",
                    ErrorEvent   => "on_client_error",
                    FlushedEvent => 'on_flush',
                    Filter       => POE::Filter::HTTPD->new(),
                );
                $_[HEAP]{client}{$w->ID()} = $w;
            },

            # 收到客户请求
            on_client_input => sub {

                # 接收请求
                eval {
                    my $req = decode_json($_[ARG0]->content());
                    warn "recv request: \n" . Data::Dump->dump($req) if $ENV{MAIN_DEBUG};
    
                    # 处理请求
                    my $json = $admin->handle($req);
    
                    # 响应请求
                    my $res     = HTTP::Response->new(200, 'OK');
                    my $content = encode_json($json);
                    $res->header( "Content-Length" => length $content );
                    $res->header( "Content-Type"   => "text/html;charset=utf-8" );
                    $res->header( "Cache-Control"  => "private" );
                    $res->content($content);
                    warn "send response: \n" . Data::Dump->dump($res) if $ENV{MAIN_DEBUG};
                    $_[HEAP]{client}{$_[ARG1]}->put($res);
                };
                if ($@) {
                   zlogger->error("can not process request, error[$@]");
                   delete $_[HEAP]{client}{$_[ARG1]};
                };

            },

            # 客户端错误
            on_client_error => sub {
                my $id = $_[ARG3];
                delete $_[HEAP]{client}{$id};
            },

            # 服务端错误
            on_server_error => sub {
                my ( $op, $errno, $errstr ) = @_[ ARG0, ARG1, ARG2 ];
                zlogger->warn("Server $op error $errno: $errstr");
                delete $_[HEAP]{server};
            },

            # 
            on_flush => sub {
                delete $_[HEAP]{client}{$_[ARG0]};
            }
        },
    );

    # 运行poe
    $poe_kernel->run();

    zlogger->error("can not create qadmin with $cfg->{qadmin}");
    zkernel->process_stopall();
    exit 0;
}


1;

__END__

