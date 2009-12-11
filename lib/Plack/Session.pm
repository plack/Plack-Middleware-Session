package Plack::Session;
use strict;
use warnings;

use Plack::Util::Accessor qw[
    id
    store
    state
];

sub new {
    my ($class, %params) = @_;
    bless {
        id    => $params{ state }->get_session_id( $params{ request } ),
        state => $params{ state },
        store => $params{ store },
    } => $class;
}

## Data Managment

sub get {
    my ($self, $key) = @_;
    $self->store->fetch( $self->id, $key )
}

sub set {
    my ($self, $key, $value) = @_;
    $self->store->store( $self->id, $key, $value );
}

sub remove {
    my ($self, $key) = @_;
    $self->store->delete( $self->id, $key );
}

## Lifecycle Management

sub expire {
    my $self = shift;
    $self->store->cleanup( $self->id );
    $self->state->expire_session_id( $self->id );
}

sub finalize {
    my $self = shift;
    $self->store->persist( $self->id )
}

1;