package Plack::Session::Store;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Plack::Util::Accessor qw[ _stash ];

sub new {
    my ($class, %params) = @_;
    $params{'_stash'} ||= +{};
    bless { %params } => $class;
}

sub fetch {
    my ($self, $session_id, $key) = @_;
    $self->_stash->{ $session_id }->{ $key }
}

sub store {
    my ($self, $session_id, $key, $data) = @_;
    $self->_stash->{ $session_id }->{ $key } = $data;
}

sub delete {
    my ($self, $session_id, $key) = @_;
    delete $self->_stash->{ $session_id }->{ $key };
}

sub cleanup {
    my ($self, $session_id) = @_;
    delete $self->_stash->{ $session_id }
}

sub persist {
    my ($self, $session_id, $response) = @_;
    ()
}

sub dump_session {
    my ($self, $session_id) = @_;
    $self->_stash->{ $session_id } || {};
}

1;

__END__

=pod

=head1 NAME

Plack::Session::Store - Basic in-memory session store

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;
  use Plack::Session::Store;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session'; # this is the defalt store
      $app;
  };

=head1 DESCRIPTION

This is a very basic in-memory session data store. It is volatile
storage and not recommended for multiprocessing environments. However
it is very useful for development and testing.

This should be considered the store "base" class (although
subclassing is not a requirement) and defines the spec for
all B<Plack::Session::Store::*> modules. You will only
need to override a couple methods if you do subclass. See
the other B<Plack::Session::Store::*> for examples of this.

=head1 METHODS

=over 4

=item B<new ( %params )>

No parameters are expected to this constructor.

=back

=head2 Session Data Management

These methods fetch data from the session storage. It can only fetch,
store or delete a single key at a time.

=over 4

=item B<fetch ( $session_id, $key )>

=item B<store ( $session_id, $key, $data )>

=item B<delete ( $session_id, $key )>

=back

=head2 Storage Management

=over 4

=item B<persist ( $session_id, $response )>

This method will perform any data persistence nessecary to maintain
data across requests. This method is called by the L<Plack::Session>
C<finalize> method. The C<$response> is expected to be a L<Plack::Response>
instance or an object with an equivalent interface.

=item B<cleanup ( $session_id )>

This method is called by the L<Plack::Session> C<expire> method and
is used to remove any session data.

=item B<dump_session ( $session_id )>

This method is mostly for debugging purposes, it will always return
a HASH ref, even if no data is actually being stored (in which case
the HASH ref will be empty).

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

