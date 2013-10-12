package Plack::Session::Store::Cache;
use strict;
use warnings;

our $VERSION   = '0.21';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util qw[ blessed ];

use parent 'Plack::Session::Store';

use Plack::Util::Accessor qw[ cache ];

sub new {
    my ($class, %params) = @_;

    die('cache require get, set and remove method.')
        unless blessed $params{cache}
            && $params{cache}->can('get')
            && $params{cache}->can('set')
            && $params{cache}->can('remove');

    bless { %params } => $class;
}

sub fetch {
    my ($self, $session_id ) = @_;
    $self->cache->get($session_id);
}

sub store {
    my ($self, $session_id, $session) = @_;
    $self->cache->set($session_id => $session);
}

sub remove {
    my ($self, $session_id) = @_;
    $self->cache->remove($session_id);
}

1;

__END__

=pod

=head1 NAME

Plack::Session::Store::Cache - Cache session store

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Session::Store::Cache;
  use CHI;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session',
          store => Plack::Session::Store::Cache->new(
              cache => CHI->new(driver => 'FastMmap')
          );
      $app;
  };

=head1 DESCRIPTION

This will persist session data using any module which implements the
L<Cache> interface. This offers a lot of flexibility due to the many
excellent L<Cache>, L<Cache::Cache> and L<CHI> drivers available.

This is a subclass of L<Plack::Session::Store> and implements
its full interface.

=head1 METHODS

=over 4

=item B<new ( %params )>

The constructor expects the I<cache> param to be an object instance
which has the I<get>, I<set>, and I<remove> methods, it will throw an
exception if that is not the case.

=item B<cache>

A simple accessor for the cache handle.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Masahiro Chiba

=cut
