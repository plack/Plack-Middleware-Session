package Plack::Session::Store;
use strict;
use warnings;

our $VERSION   = '0.21';
our $AUTHORITY = 'cpan:STEVAN';

use Plack::Util::Accessor qw[ _stash ];

sub new {
    my ($class, %params) = @_;
    $params{'_stash'} ||= +{};
    bless { %params } => $class;
}

sub fetch {
    my ($self, $session_id) = @_;
    $self->_stash->{ $session_id };
}

sub store {
    my ($self, $session_id, $session) = @_;
    $self->_stash->{ $session_id } = $session;
}

sub remove {
    my ($self, $session_id) = @_;
    delete $self->_stash->{ $session_id }
}

1;

__END__

=pod

=head1 NAME

Plack::Session::Store - Basic in-memory session store

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;
  use Plack::Session::Store;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session'; # this is the defalt store
      $app;
  };

=head1 DESCRIPTION

This is a very basic in-memory session data store. It is volatile
storage and not recommended for multiprocessing environments. However
it is very useful for development and testing.

This should be considered the store "base" class (although
subclassing is not a requirement) and defines the spec for
all B<Plack::Session::Store::*> modules. You will only
need to override a couple methods if you do subclass. See
the other B<Plack::Session::Store::*> for examples of this.

=head1 METHODS

=over 4

=item B<new ( %params )>

No parameters are expected to this constructor.

=back

=head2 Session Data Management

These methods fetch data from the session storage. It's designed to
store or delete multiple keys at a time.

=over 4

=item B<fetch ( $session_id )>

=item B<store ( $session_id, $session )>

=back

=head2 Storage Management

=over 4

=item B<remove ( $session_id )>

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

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

