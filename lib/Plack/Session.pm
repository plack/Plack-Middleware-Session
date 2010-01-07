package Plack::Session;
use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use Plack::Util::Accessor qw[
    id
    store
    state
];

sub new {
    my ($class, %params) = @_;
    my $request = delete $params{'request'};
    $params{'id'} = $params{'state'}->get_session_id( $request );
    bless { %params } => $class;
}

## Data Managment

sub get {
    my ($self, $key) = @_;
    $self->store->fetch( $self->id, $key )
}

sub set {
    my ($self, $key, $value) = @_;
    $self->store->store( $self->id, $key, $value );
}

sub remove {
    my ($self, $key) = @_;
    $self->store->delete( $self->id, $key );
}

## Lifecycle Management

sub expire {
    my $self = shift;
    $self->store->cleanup( $self->id );
    $self->state->expire_session_id( $self->id );
}

sub finalize {
    my ($self, $response) = @_;
    $self->store->persist( $self->id, $response );
    $self->state->finalize( $self->id, $response );
}

1;

__END__

=pod

=head1 NAME

Plack::Session - Middleware for session management

=head1 SYNOPSIS

  use Plack::Session;

  my $store = Plack::Session::Store->new;
  my $state = Plack::Session::State->new;

  my $s = Plack::Session->new(
      store   => $store,
      state   => $state,
      request => Plack::Request->new( $env )
  );

  # ...

=head1 DESCRIPTION

This is the core session object, you probably want to look
at L<Plack::Middleware::Session>, unless you are writing your
own session middleware component.

=head1 METHODS

=over 4

=item B<new ( %params )>

The constructor expects keys in C<%params> for I<state>,
I<store> and I<request>. The I<request> param is expected to be
a L<Plack::Request> instance or an object with an equivalent
interface.

=item B<id>

This is the accessor for the session id.

=item B<state>

This is expected to be a L<Plack::Session::State> instance or
an object with an equivalent interface.

=item B<store>

This is expected to be a L<Plack::Session::Store> instance or
an object with an equivalent interface.

=back

=head2 Session Data Storage

These methods delegate to appropriate methods on the C<store>
to manage your session data.

=over 4

=item B<get ( $key )>

=item B<set ( $key, $value )>

=item B<remove ( $key )>

=back

=head2 Session Lifecycle Management

=over 4

=item B<expire>

This method can be called to expire the current session id. It
will call the C<cleanup> method on the C<store> and the C<finalize>
method on the C<state>, passing both of them the session id and
the C<$response>.

=item B<finalize ( $response )>

This method should be called at the end of the response cycle. It
will call the C<persist> method on the C<store> and the
C<expire_session_id> method on the C<state>, passing both of them
the session id. The C<$response> is expected to be a L<Plack::Response>
instance or an object with an equivalent interface.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

