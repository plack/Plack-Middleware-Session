package Plack::Session::Store::File;
use strict;
use warnings;

our $VERSION   = '0.21';
our $AUTHORITY = 'cpan:STEVAN';

use Storable ();

use parent 'Plack::Session::Store';

use Plack::Util::Accessor qw[
    dir
    serializer
    deserializer
];

sub new {
    my ($class, %params) = @_;

    $params{'dir'} ||= $ENV{TMPDIR} || '/tmp';

    die "Storage directory (" . $params{'dir'} . ") is not writeable"
        unless -w $params{'dir'};

    $params{'serializer'}   ||= sub { Storable::lock_nstore( @_ ) };
    $params{'deserializer'} ||= sub { Storable::lock_retrieve( @_ ) };

    bless { %params } => $class;
}

sub fetch {
    my ($self, $session_id) = @_;

    my $file_path = $self->_get_session_file_path( $session_id );
    return unless -f $file_path;

    $self->deserializer->( $file_path );
}

sub store {
    my ($self, $session_id, $session) = @_;
    my $file_path = $self->_get_session_file_path( $session_id );
    $self->serializer->( $session, $file_path );
}

sub remove {
    my ($self, $session_id) = @_;
    unlink $self->_get_session_file_path( $session_id );
}

sub _get_session_file_path {
    my ($self, $session_id) = @_;
    $self->dir . '/' . $session_id;
}

1;

__END__

=pod

=head1 NAME

Plack::Session::Store::File - Basic file-based session store

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;
  use Plack::Session::Store::File;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session',
          store => Plack::Session::Store::File->new(
              dir => '/path/to/sessions'
          );
      $app;
  };

  # with custom serializer/deserializer

  builder {
      enable 'Session',
          store => Plack::Session::Store::File->new(
              dir          => '/path/to/sessions',
              # YAML takes it's args the opposite order
              serializer   => sub { YAML::DumpFile( reverse @_ ) },
              deserializer => sub { YAML::LoadFile( @_ ) },
          );
      $app;
  };

=head1 DESCRIPTION

This implements a basic file based storage for session data. By
default it will use L<Storable> to serialize and deserialize the
data, but this can be configured easily. 

This is a subclass of L<Plack::Session::Store> and implements
its full interface.

=head1 METHODS

=over 4

=item B<new ( %params )>

The C<%params> can include I<dir>, I<serializer> and I<deserializer>
options. It will check to be sure that the I<dir> is writeable for
you.

=item B<dir>

This is the directory to store the session data files in, if nothing
is provided then "/tmp" is used.

=item B<serializer>

This is a CODE reference that implements the serialization logic.
The CODE ref gets two arguments, the C<$value>, which is a HASH
reference to be serialized, and the C<$file_path> to save it to.
It is not expected to return anything.

=item B<deserializer>

This is a CODE reference that implements the deserialization logic.
The CODE ref gets one argument, the C<$file_path> to load the data
from. It is expected to return a HASH reference.

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

