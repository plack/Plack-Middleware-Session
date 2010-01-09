package Plack::Middleware::Session;
use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

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

    $self->state( 'Cookie' ) unless $self->state;
    $self->state( $self->inflate_backend('Plack::Session::State', $self->state) );
    $self->store( $self->inflate_backend('Plack::Session::Store', $self->store) );

    Plack::Util::load_class($self->session_class) if $self->session_class;
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

    my $request = Plack::Request->new($env);

    my($id, $session) = $self->get_session($request);
    if ($id && $session) {
        $env->{'psgix.session'} = $session;
    } else {
        $id = $self->generate_id($request);
        $env->{'psgix.session'} = {};
    }

    $env->{'psgix.session.options'} = { id => $id };

    if ($self->session_class) {
        $env->{'plack.session'} = $self->session_class->new($env);
    }

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = Plack::Response->new(@{$_[0]});
        $self->finalize($request, $res);
        $res = $res->finalize;
        $_[0]->[0] = $res->[0];
        $_[0]->[1] = $res->[1];
    });
}

sub get_session {
    my($self, $request) = @_;

    my $id = $self->state->extract($request) or return;
    my $session = $self->store->fetch($id)   or return;

    return ($id, $session);
}

sub generate_id {
    my($self, $request) = @_;
    $self->state->generate($request);
}

sub commit {
    my($self, $session, $options) = @_;
    if ($options->{expire}) {
        $self->store->remove($options->{id});
    } else {
        $self->store->store($options->{id}, $session);
    }
}

sub finalize {
    my($self, $request, $response) = @_;

    my $session = $request->env->{'psgix.session'};
    my $options = $request->env->{'psgix.session.options'};

    $self->commit($session, $options) unless $options->{no_store};
    if ($options->{expire}) {
        $self->expire_session($options->{id}, $response, $session, $options);
    } else {
        $self->save_state($options->{id}, $response, $session, $options);
    }
}

sub expire_session {
    my($self, $id, $res, $session, $options) = @_;
    $self->state->expire_session_id($options->{id}, $res, $options);
}

sub save_state {
    my($self, $id, $res, $session, $options) = @_;
    $self->state->finalize($id, $res, $options);
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
      my $session = $env->{'psgix.session'};
      return [
          200,
          [ 'Content-Type' => 'text/plain' ],
          [ "Hello, you've been here for ", $session->{counter}++, "th time!" ],
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

It should be noted that we store the current session as a hash
reference in the C<psgix.session> key inside the C<$env> where you can
access it as needed.

B<NOTE:> As of version 0.04 the session is stored in C<psgix.session>
instead of C<plack.session>.

Also, if you set I<session_class> option (see below), we create a
session object out of the hash reference in C<plack.session>.

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

This can be used to create an actual session object in
C<plack.session> environment. Defaults to none, which means the
session object is not created but you can set C<Plack::Session> to
create an object for you.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Tatsuhiko Miyagawa

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


