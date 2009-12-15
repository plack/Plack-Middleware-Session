package Plack::Middleware::Session;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Plack::Session;
use Plack::Request;
use Plack::Response;
use Plack::Util;
use Scalar::Util;

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw(
    state
    store
    session_class
);

sub prepare_app {
    my $self = shift;

    $self->session_class( 'Plack::Session' ) unless $self->session_class;
    $self->state( 'Cookie' )                 unless $self->state;

    $self->state( $self->inflate_backend('Plack::Session::State', $self->state) );
    $self->store( $self->inflate_backend('Plack::Session::Store', $self->store) );
}

sub inflate_backend {
    my($self, $prefix, $backend) = @_;

    return $backend if defined $backend && Scalar::Util::blessed $backend;

    my @class;
    push @class, $backend if defined $backend; # undef means the root class
    push @class, $prefix;

    Plack::Util::load_class(@class)->new();
}

sub call {
    my $self = shift;
    my $env  = shift;

    $env->{'plack.session'} = $self->session_class->new(
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

  my $app = sub {
      my $env = shift;
      return [
          200,
          [ 'Content-Type' => 'text/plain' ],
          [ 'Hello, your Session ID is ' . $env->{'plack.session'}->id ]
      ];
  };

  builder {
      enable 'Session';
      $app;
  };

  # Or, use the File store backend (great if you use multiprocess server)
  # For more options, see perldoc Plack::Session::Store::File
  builder {
      enable 'Session', store => 'File';
      $app;
  };

=head1 DESCRIPTION

This is a Plack Middleware component for session management. By
default it will use cookies to keep session state and store data in
memory. This distribution also comes with other state and store
solutions. See perldoc for these backends how to use them.

It should be noted that we store the current session in the
C<plack.session> key inside the C<$env> where you can access it
as needed. Additionally, as of version 0.09, you can call the
C<session> method of a L<Plack::Request> instance to fetch
whatever is stored in C<plack.session>.

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

=item L<Plack::Session::Store::Cache>

This will persist session data using the L<Cache> interface.

=item L<Plack::Session::Store::Null>

Sometimes you don't care about storing session data, in that case
you can use this noop module.

=back

=head1 OPTIONS

The following are options that can be passed to this mdoule.

=over 4

=item I<state>

This is expected to be an instance of L<Plack::Session::State> or an
object that implements the same interface. If no option is provided
the default L<Plack::Session::State::Cookie> will be used.

=item I<store>

This is expected to be an instance of L<Plack::Session::Store> or an
object that implements the same interface. If no option is provided
the default L<Plack::Session::Store> will be used.

It should be noted that this default is an in-memory volatile store
is only suitable for development (or single process servers). For a
more robust solution see L<Plack::Session::Store::File> or
L<Plack::Session::Store::Cache>.

=item I<session_class>

This can be used to override the actual session class. It currently
defaults to L<Plack::Session> but you can substitute any class which
implements the same interface.

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


