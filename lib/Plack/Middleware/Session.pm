package Plack::Middleware::Session;
use strict;
use warnings;

use Plack::Session;
use Plack::Request;
use Plack::Response;

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw( state store );

sub call {
    my $self = shift;
    my $env  = shift;

    $env->{'psgix.session'} = Plack::Session->new(
        state   => $self->state,
        store   => $self->store,
        request => Plack::Request->new( $env )
    );

    my $res = Plack::Response->new( @{ $self->app->( $env ) } );

    $env->{'psgix.session'}->finalize( $res );

    $res->finalize();
}

1;

__END__
