package Plack::Session::State::Cookie;
use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

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

sub get_session_id_from_request {
    my ($self, $request) = @_;
    ( $request->cookie( $self->session_key ) || return )->value;
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

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session'; # Cookie is the default state
      $app;
  };

=head1 DESCRIPTION

This is a subclass of L<Plack::Session::State> and implements it's
full interface. This is the default state used in
L<Plack::Middleware::Session>.

=head1 METHODS

=over 4

=item B<new ( %params )>

The C<%params> can include I<path>, I<domain>, I<expires> and
I<secure> options, as well as all the options accepted by
L<Plack::Session::Store>.

=item B<path>

Path of the cookie, this defaults to "/";

=item B<domain>

Domain of the cookie, if nothing is supplied then it will not
be included in the cookie.

=item B<expires>

Expiration time of the cookie, if nothing is supplied then it will
not be included in the cookie.

=item B<secure>

Secure flag for the cookie, if nothing is supplied then it will not
be included in the cookie.

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


