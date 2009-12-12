package Plack::Middleware::Session;
use strict;
use warnings;

use Plack::Session;
use Plack::Request;
use Plack::Response;
use Plack::Session::State::Cookie;
use Plack::Session::Store;

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw( state store );

sub prepare_app {
    my $self = shift;
    unless ($self->state) {
        $self->state( Plack::Session::State::Cookie->new );
    }

    unless ($self->store) {
        $self->store( Plack::Session::Store->new );
    }
}

sub call {
    my $self = shift;
    my $env  = shift;

    $env->{'psgix.session'} = Plack::Session->new(
        state   => $self->state || $self->default_state,
        store   => $self->store,
        request => Plack::Request->new( $env )
    );

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = Plack::Response->new(@{$_[0]});
        $env->{'psgix.session'}->finalize( $res );
        @{$_[0]} = @{$res->finalize};
    });
}

1;

__END__
