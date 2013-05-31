package Zeta::IPC::MsgQ;

use strict;
use warnings;

use Carp qw/cluck/;
use Errno;
use IPC::SysV qw(IPC_NOWAIT MSG_NOERROR S_IRUSR S_IWUSR IPC_CREAT IPC_EXCL IPC_STAT IPC_RMID);

#
# 
#
sub new {
    my $class = shift;
    my $key   = shift;

    unless ( defined $key ) {
        cluck "msgget key undefined";
        return;
    }

    my $id = msgget( $key, S_IRUSR | S_IWUSR | IPC_CREAT | IPC_EXCL );
    unless ( defined $id ) {
        if ( $!{EEXIST} ) {
            $id = msgget( $key, S_IRUSR | S_IWUSR );
            unless ( defined $id ) {
                cluck "msgget error: [$!]";
                return;
            }
        }
        else {
            cluck "msgget error: [$!]";
            return;
        }
    }

    # warn "got QID[$id]";
    bless \$id, $class;

}

#
#
#
sub delete {
    my $class_self = shift;
    my $id         = shift;
    if ( ref $class_self ) {
        $id = $$class_self;
    }
    return msgctl( $id, IPC_RMID, MSG_NOERROR );
}

#
################################################
# $q->send($msg, $mtype);
################################################
#
sub send {

    my $self = shift;
    my ( $msg, $mtype ) = @_;

    # warn "kkkkkkkkkkkk: $msg, $mtype";
    unless ( defined $msg ) {
        cluck "$msg undefinded";
        return;
    }

    unless ( defined $mtype ) {
        cluck "mtype undefined";
        return;
    }

    # warn "begin msgsnd($$self, $msg, $mtype)";
    unless ( msgsnd( $$self, pack( "l! a*", $mtype, $msg ), IPC_NOWAIT ) ) {
        if ( $!{EAGAIN} ) {
            warn "queue $$self is full, message dropped";
            return;
        }
    }
    return $self;
}

#
# $q->msgrcv(\$data, \$mtype);
#
sub recv {

    my $self = shift;
    my ( $dref, $tref ) = @_;

    my $mtype = $$tref;
    $mtype ||= 0;

RETRY:
    unless ( msgrcv( $$self, $$dref, 8192, $$tref, MSG_NOERROR ) ) {
        if ( $!{EINTR} ) {
            goto RETRY;
        }
        cluck "msgrcv error";
        return;
    }
    ($mtype , $$dref) = unpack("l!a*", $$dref);
    if ($tref) {
        $$tref = $mtype;
    }
    return $self;

}

#
# $q->stat();
#
sub stat {
    my $self = shift;
    my $stat;
    msgctl( $$self, IPC_STAT, $stat );
    use Data::Dump;
    Data::Dump->dump($stat);
}

#
# $q->msgrcv(\$data, $tref);
#
sub recv_nw {
    my $self  = shift;
    my ($dref, $tref) = @_;

    my $mtype = $$tref;
    unless ( msgrcv( $$self, $$dref, 8192, $mtype, MSG_NOERROR | IPC_NOWAIT ) ) {
        if ($!{EAGAIN}) {
            return;
        }
    }
    return $self;
}

1;

__END__


=head1 NAME

  Zeta::IPC::MsgQ  - a simple wrapper for msgget msgrecv msgsnd 


=head1 SYNOPSIS

  ##################################################
  #  send.pl
  ##################################################
  #!/usr/bin/perl -w
  use strict;

  my $q = Zeta::IPC::MsgQ->new(999000);
  while(1) {
    $q->send("this is a test");
  }
  exit 0;


  ##################################################
  #  recv.pl
  ##################################################
  #!/usr/bin/perl -w
  use strict;

  my $q = Zeta::IPC::MsgQ->new(999000);
  my $data;
  my $type;
  while(1) {
    $q->recv(\$data \$type);
    $msg = substr($data, 0, $Config{longsize});  # remove msgtype;
    warn "got msg[$msg]\n";
  }
  $q->delete();  #  or Zeta::IPC::MsgQ->delete($id)
  
  exit 0;


=head1 Author & Copyright

  zcman2005@gmail.com

=cut


