package Plack::Session::State;
use strict;
use warnings;

use Plack::Util::Accessor qw[ session_key ];

sub new {
    my ($class, %params) = @_;
    bless {
        session_key => $params{ session_key } || 'plack_session',
        expired     => {}
    } => $class;
}

sub expire_session_id {
    my ($self, $id) = @_;
    $self->{expired}->{ $id }++;
}

sub check_expired {
    my ($self, $id) = @_;
    return unless $id && not exists $self->{expired}->{ $id };
    return $id;
}

# given a request, get the
# session id from it
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

{
    my $id = 1;
    sub generate { $id++ }
}

sub finalize {
    my ($self, $id, $response) = @_;
    ();
}

1;