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

=pod

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
      enable 'Session',
          store => Plack::Session::Store::CHI->new(
              chi => CHI->new(driver => 'FastMmap')
          );
      $app;
  };

=head1 DESCRIPTION

This will persist session data using the L<CHI> module. This
offers a lot of flexibility due to the many excellent L<CHI>
drivers available.

This is a subclass of L<Plack::Session::Store> and implements
it's full interface.

=head1 METHODS

=over 4

=item B<new ( %params )>

The constructor expects an the I<chi> param to be an
instance of L<CHI::Driver>, it will throw an exception
if that is not the case.

=item B<chi>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Masahiro Chiba

=cut
