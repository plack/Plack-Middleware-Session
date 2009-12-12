package Plack::Session::State::Cookie;
use strict;
use warnings;

use parent 'Plack::Session::State';

use Plack::Util::Accessor qw[ path domain expires secure ];

sub expire_session_id {
    my ($self, $id) = @_;
    $self->SUPER::expire_session_id( $id );
    $self->expires( 0 );
}

sub extract {
    my ($self, $request) = @_;
    $self->check_expired( ( $request->cookie( $self->session_key ) || return )->value );
}

sub finalize {
    my ($self, $id, $response) = @_;
    $response->cookies->{ $self->session_key } = +{
        value => $id,
        path  => ($self->path || '/'),
        ( $self->domain  ? ( domain  => $self->domain  ) : () ),
        ( $self->expires ? ( expires => $self->expires ) : () ),
        ( $self->secure  ? ( secure  => $self->secure  ) : () ),
    };
}

1;