package Plack::Middleware::Session;
use strict;
use warnings;

use Plack::Session;
use Plack::Request;
use Plack::Response;
use Plack::Session::State::Cookie;
use Plack::Session::Store;

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw( state store );

sub prepare_app {
    my $self = shift;
    unless ($self->state) {
        $self->state( Plack::Session::State::Cookie->new );
    }

    unless ($self->store) {
        $self->store( Plack::Session::Store->new );
    }
}

sub call {
    my $self = shift;
    my $env  = shift;

    $env->{'plack.session'} = Plack::Session->new(
        state   => $self->state,
        store   => $self->store,
        request => Plack::Request->new( $env )
    );

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = Plack::Response->new(@{$_[0]});
        $env->{'plack.session'}->finalize( $res );
        @{$_[0]} = @{$res->finalize};
    });
}

1;

__END__

=pod

=head1 NAME

Plack::Middleware::Session - Middleware for session management

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session';
      $app;
  };

=head1 DESCRIPTION

This is a Plack Middleware component for session management. By
default it will use cookies to keep session state and store data
in memory. This distribution comes also comes with other state
and store solutions.

=head2 State

=over 4

=item L<Plack::Session::State>

This will maintain session state by passing the session through
the request params. It does not do this automatically though,
you are responsible for passing the session param.

=item L<Plack::Session::State::Cookie>

This will maintain session state using browser cookies.

=back

=head2 Store

=over 4

=item L<Plack::Session::Store>

This is your basic in-memory session data store. It is volatile storage
and not recommended for multiprocessing environments. However it is
very useful for development and testing.

=item L<Plack::Session::Store::File>

This will persist session data in a file. By default it uses
L<Storable> but it can be configured to have a custom serializer and
deserializer.

=item L<Plack::Session::Store::CHI>

This will persist session data using the L<CHI> module. This
offers a lot of flexibility due to the many excellent L<CHI>
drivers available.

=item L<Plack::Session::Store::Null>

Sometimes you don't care about storing session data, in that case
you can use this noop module.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Tatsuhiko Miyagawa

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


