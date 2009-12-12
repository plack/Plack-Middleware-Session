package Plack::Session::State;
use strict;
use warnings;

use Plack::Util::Accessor qw[
    session_key
    sid_generator
];

sub new {
    my ($class, %params) = @_;

    $params{'_expired'}      ||= +{};
    $params{'session_key'}   ||= 'plack_session';
    $params{'sid_generator'} ||= sub {
        require Digest::SHA1;
        Digest::SHA1::sha1_hex(rand() . $$ . {} . time)
    };

    bless { %params } => $class;
}

sub expire_session_id {
    my ($self, $id) = @_;
    $self->{'_expired'}->{ $id }++;
}

sub is_session_expired {
    my ($self, $id) = @_;
    exists $self->{'_expired'}->{ $id }
}

sub check_expired {
    my ($self, $id) = @_;
    return unless $id && not $self->is_session_expired( $id );
    return $id;
}

sub get_session_id {
    my ($self, $request) = @_;
    $self->extract( $request )
        ||
    $self->generate( $request )
}

sub extract {
    my ($self, $request) = @_;
    $self->check_expired( $request->param( $self->session_key ) );
}

sub generate {
    my $self = shift;
    $self->sid_generator->( @_ );
}


sub finalize {
    my ($self, $id, $response) = @_;
    ();
}

1;

__END__

=pod

=head1 NAME

Plack::Session::State - Basic parameter-based session state

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new ( %params )>

=item B<session_key>

=item B<sid_generator>

=back

=over 4

=item B<get_session_id ( $request )>

=item B<extract ( $request )>

=item B<generate ( $request )>

=item B<finalize ( $session_id, $response )>

=back

=over 4

=item B<expire_session_id ( $id )>

=item B<check_expired ( $id )>

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


