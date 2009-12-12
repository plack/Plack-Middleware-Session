package Plack::Session::State;
use strict;
use warnings;

use Plack::Util::Accessor qw[
    session_key
    sid_generator
];

sub new {
    my ($class, %params) = @_;

    $params{'_expired'}      ||= +{};
    $params{'session_key'}   ||= 'plack_session';
    $params{'sid_generator'} ||= sub {
        require Digest::SHA1;
        Digest::SHA1::sha1_hex(rand() . $$ . {} . time)
    };

    bless { %params } => $class;
}

sub expire_session_id {
    my ($self, $id) = @_;
    $self->{'_expired'}->{ $id }++;
}

sub is_session_expired {
    my ($self, $id) = @_;
    exists $self->{'_expired'}->{ $id }
}

sub check_expired {
    my ($self, $id) = @_;
    return unless $id && not $self->is_session_expired( $id );
    return $id;
}

sub get_session_id {
    my ($self, $request) = @_;
    $self->extract( $request )
        ||
    $self->generate( $request )
}

sub extract {
    my ($self, $request) = @_;
    $self->check_expired( $request->param( $self->session_key ) );
}

sub generate {
    my $self = shift;
    $self->sid_generator->( @_ );
}


sub finalize {
    my ($self, $id, $response) = @_;
    ();
}

1;

__END__

=pod

=head1 NAME

Plack::Session::State - Basic parameter-based session state

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new ( %params )>

=item B<session_key>

This is the name of the session key, it default to 'plack_session'.

=item B<sid_generator>

This is a CODE ref used to generate unique session ids.

=back

=head2 Session ID Managment

=over 4

=item B<get_session_id ( $request )>

Given a C<$request> this will first attempt to extract the session,
if the is expired or does not exist, it will then generate a new
session. The C<$request> is expected to be a L<Plack::Request> instance
or an object with an equivalent interface.

=item B<extract ( $request )>

This will attempt to extract the session from a C<$request> by looking
for the C<session_key> in the C<$request> params. It will then check to
see if the session has expired and return the session id if it is not.
The C<$request> is expected to be a L<Plack::Request> instance or an
object with an equivalent interface.

=item B<generate ( $request )>

This will generate a new session id using the C<sid_generator> callback.
The C<$request> argument is not used by this method but is there for
use by subclasses. The C<$request> is expected to be a L<Plack::Request>
instance or an object with an equivalent interface.

=item B<finalize ( $session_id, $response )>

Given a C<$session_id> and a C<$response> this will perform any
finalization nessecary to preserve state. This method is called by
the L<Plack::Session> C<finalize> method. The C<$response> is expected
to be a L<Plack::Response> instance or an object with an equivalent
interface.

=back

=head2 Session Expiration Handling

=over 4

=item B<expire_session_id ( $id )>

This will mark the session for C<$id> as expired. This method is called
by the L<Plack::Session> C<expire> method.

=item B<is_session_expired ( $id )>

This will check to see if the session C<$id> has been marked as
expired.

=item B<check_expired ( $id )>

Given an session C<$id> this will return C<undef> if the session is
expired or return the C<$id> if it is not.

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


