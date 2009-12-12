package Plack::Session::State::Cookie;
use strict;
use warnings;

use parent 'Plack::Session::State';

use Plack::Util::Accessor qw[
    path
    domain
    expires
    secure
];

sub expire_session_id {
    my ($self, $id) = @_;
    $self->SUPER::expire_session_id( $id );
    $self->expires( 0 );
}

sub extract {
    my ($self, $request) = @_;
    $self->check_expired( ( $request->cookie( $self->session_key ) || return )->value );
}

sub finalize {
    my ($self, $id, $response) = @_;
    $response->cookies->{ $self->session_key } = +{
        value => $id,
        path  => ($self->path || '/'),
        ( defined $self->domain  ? ( domain  => $self->domain  ) : () ),
        ( defined $self->expires ? ( expires => $self->expires ) : () ),
        ( defined $self->secure  ? ( secure  => $self->secure  ) : () ),
    };

    # clear the expires after
    # finalization if the session
    # has been expired - SL
    $self->expires( undef )
        if defined $self->expires
        && $self->expires == 0
        && $self->is_session_expired( $id );
}

1;

__END__

=pod

=head1 NAME

Plack::Session::State::Cookie - Basic cookie-based session state

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new ( %params )>

=item B<path>

=item B<domain>

=item B<expires>

=item B<secure>

=back

=over 4

=item B<extract ( $request )>

=item B<finalize ( $session_id, $response )>

=back

=over 4

=item B<expire_session_id ( $id )>

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


