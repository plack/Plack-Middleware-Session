package Plack::Session::State;
use strict;
use warnings;

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:STEVAN';

use Digest::SHA1 ();

use Plack::Request;
use Plack::Util::Accessor qw[
    session_key
    sid_generator
    sid_validator
];

sub new {
    my ($class, %params) = @_;

    $params{'session_key'}   ||= 'plack_session';
    $params{'sid_generator'} ||= sub {
        Digest::SHA1::sha1_hex(rand() . $$ . {} . time)
    };
    $params{'sid_validator'} ||= qr/\A[0-9a-f]{40}\Z/;

    bless { %params } => $class;
}

sub expire_session_id {
    my ($self, $id, $res) = @_;
}

sub validate_session_id {
    my ($self, $id) = @_;
    $id =~ $self->sid_validator;
}

sub get_session_id {
    my ($self, $env) = @_;
    return Plack::Request->new($env)->param( $self->session_key );
}

sub extract {
    my ($self, $env) = @_;

    my $id = $self->get_session_id( $env );
    return unless defined $id;

    return $id if $self->validate_session_id( $id );
    return;
}

sub generate {
    my $self = shift;
    $self->sid_generator->( @_ );
}


sub finalize {
    my ($self, $id, $res, $options) = @_;
    ();
}

1;

__END__

=pod

=head1 NAME

Plack::Session::State - Basic parameter-based session state

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;
  use Plack::Session::State;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session',
          state => Plack::Session::State->new;
      $app;
  };

=head1 DESCRIPTION

This will maintain session state by passing the session through
the request params. It does not do this automatically though,
you are responsible for passing the session param.

This should be considered the state "base" class (although
subclassing is not a requirement) and defines the spec for
all B<Plack::Session::State::*> modules. You will only
need to override a couple methods if you do subclass. See
L<Plack::Session::State::Cookie> for an example of this.

B<WARNING>: parameter based session ID management makes session
fixation really easy, and that makes your website vulnerable. You
should really avoid using this state in the production environment
except when you have to deal with legacy HTTP clients that do not
support cookies.

In the future this parameter based state handling will be removed from
this base class and will be moved to its own State class.

=head1 METHODS

=over 4

=item B<new ( %params )>

The C<%params> can include I<session_key>, I<sid_generator> and I<sid_checker>
however in both cases a default will be provided for you.

=item B<session_key>

This is the name of the session key, it defaults to 'plack_session'.

=item B<sid_generator>

This is a CODE ref used to generate unique session ids, by default
it will generate a SHA1 using fairly sufficient entropy. If you are
concerned or interested, just read the source.

=item B<sid_validator>

This is a regex used to validate requested session id.

=back

=head2 Session ID Managment

=over 4

=item B<get_session_id ( $env )>

This is the method used to extract the session id from a C<$env>.
Subclasses will often only need to override this method and the
C<finalize> method.

=item B<validate_session_id ( $session_id )>

This will use the C<sid_validator> regex and confirm that the
C<$session_id> is valid.

=item B<extract ( $env )>

This will attempt to extract the session from a C<$env> by looking
for the C<session_key> in the request params. It will then check to
see if the session is valid and that it has not expired. It will return
the session id if everything is good or undef otherwise.

=item B<generate ( $request )>

This will generate a new session id using the C<sid_generator> callback.
The C<$request> argument is not used by this method but is there for
use by subclasses. The C<$request> is expected to be a L<Plack::Request>
instance or an object with an equivalent interface.

=item B<finalize ( $session_id, $response )>

Given a C<$session_id> and a C<$response> this will perform any
finalization necessary to preserve state. This method is called by
the L<Plack::Session> C<finalize> method. The C<$response> is expected
to be a L<Plack::Response> instance or an object with an equivalent
interface.

=back

=head2 Session Expiration Handling

=over 4

=item B<expire_session_id ( $id, $response )>

This will mark the session for C<$id> as expired. This method is called
by the L<Plack::Session> C<expire> method.

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


