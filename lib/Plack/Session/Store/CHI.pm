package Plack::Session::Store::CHI;
use strict;
use warnings;

use Scalar::Util qw/blessed/;

use parent 'Plack::Session::Store';

use Plack::Util::Accessor qw[ chi ];

sub new {
    my ($class, %params) = @_;
    unless ( blessed $params{chi} and $params{chi}->isa('CHI::Driver') ) {
        die('require chi driver');
    }
    bless { %params } => $class;
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

sub cleanup {
    my ($self, $session_id) = @_;
    $self->chi->remove($session_id);
}

1;

__END__

=head1 NAME

Plack::Session::Store::CHI - CHI session store

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

=head1 METHODS

=over 4

=item B<new ( %params )>

=back

=over 4

=item B<fetch ( $session_id, $key )>

=item B<store ( $session_id, $key, $data )>

=item B<delete ( $session_id, $key )>

=back

=over 4

=item B<cleanup ( $session_id )>

=back

=head1 AUTHOR

Masahiro Chiba

=cut
