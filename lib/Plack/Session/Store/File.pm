package Plack::Session::Store::File;
use strict;
use warnings;

use Storable ();

use parent 'Plack::Session::Store';

use Plack::Util::Accessor qw[
    dir
    serializer
    deserializer
];

sub new {
    my ($class, %params) = @_;

    $params{'dir'} ||= '/tmp';

    die "Storage directory (" . $params{'dir'} . ") is not writeable"
        unless -w $params{'dir'};

    $params{'serializer'}   ||= sub { Storable::nstore( @_ ) };
    $params{'deserializer'} ||= sub { Storable::retrieve( @_ ) };

    $class->SUPER::new( %params );
}

sub fetch {
    my ($self, $session_id, $key) = @_;
    $self->_deserialize( $session_id )->{ $key };
}

sub store {
    my ($self, $session_id, $key, $data) = @_;
    my $store = $self->_deserialize( $session_id );
    $store->{ $key } = $data;
    $self->_serialize( $session_id, $store );
}

sub delete {
    my ($self, $session_id, $key) = @_;
    my $store = $self->_deserialize( $session_id );
    delete $store->{ $key };
    $self->_serialize( $session_id, $store );
}

sub cleanup {
    my ($self, $session_id) = @_;
    unlink $self->_get_session_file_path( $session_id );
}

sub _get_session_file_path {
    my ($self, $session_id) = @_;
    $self->dir . '/' . $session_id;
}

sub _serialize {
    my ($self, $session_id, $value) = @_;
    my $file_path = $self->_get_session_file_path( $session_id );
    $self->serializer->( $value, $file_path );
}

sub _deserialize {
    my ($self, $session_id) = @_;
    my $file_path = $self->_get_session_file_path( $session_id );
    $self->_serialize( $session_id, {} ) unless -f $file_path;
    $self->deserializer->( $file_path );
}


1;

__END__

=pod

=head1 NAME

Plack::Session::Store::File - Basic file-based session store

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new ( %params )>

=item B<dir>

=item B<serializer>

=item B<deserializer>

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

