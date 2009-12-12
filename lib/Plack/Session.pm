package Plack::Session;
use strict;
use warnings;

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

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new ( %params )>

=item B<id>

=item B<state>

=item B<store>

=back

=over 4

=item B<get ( $key )>

=item B<set ( $key, $value )>

=item B<remove ( $key )>

=back

=over 4

=item B<expire>

=item B<finalize ( $response )>

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

