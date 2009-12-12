package Plack::Session::Store;
use strict;
use warnings;

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

1;

__END__

=pod

=head1 NAME

Plack::Session::Store - Basic in-memory session store

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new ( %params )>

=back

=head2 Session Data Management

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

