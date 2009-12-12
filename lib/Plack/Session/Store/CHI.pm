package Plack::Session::Store::CHI;
use strict;
use warnings;

use Plack::Util::Accessor qw[ chi ];
use Scalar::Util qw/blessed/;

sub new {
    my ($class, %params) = @_;
    unless ( blessed $params{chi} and $params{chi}->isa('CHI::Driver') ) {
        die('require chi driver');
    }
    bless {
        chi => $params{chi},
    } => $class;
}

sub fetch {
    my ($self, $session_id, $key) = @_;
    my $cache = $self->chi->get($session_id);
    return unless $cache;
    return $cache->{ $key };
}

sub store {
    my ($self, $session_id, $key, $data) = @_;
    my $cache = $self->chi->get($session_id);
    if ( !$cache ) {
        $cache = {$key => $data};
    }
    else {
        $cache->{$key} = $data;
    }
    $self->chi->set($session_id => $cache);
}

sub delete {
    my ($self, $session_id, $key) = @_;
    my $cache = $self->chi->get($session_id);
    return unless exists $cache->{$key};

    delete $cache->{ $key };
    $self->chi->set($session_id => $cache);
}

sub persist {
    my ($self, $session_id) = @_;
    ()
}

sub cleanup {
    my ($self, $session_id) = @_;
    $self->chi->remove($session_id);
}

1;

__END__

=head1 NAME

Plack::Session::Store::CHI

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Session::Store::CHI;
  use CHI;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session', store => Plack::Session::Store::CHI->new(chi => CHI->new(driver => 'FastMmap'));
      $app;
  };


=head1 AUTHOR

Masahiro Chiba

=cut
