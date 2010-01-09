use strict;
use Test::More;
use Plack::Test;
use Plack::Middleware::Session;
use HTTP::Request::Common;

$Plack::Test::Impl = 'Server';

my $app = sub {
    return sub {
        my $respond = shift;
        my $w = $respond->([ 200, [ 'Content-Type' => 'text/html' ] ]);
        $w->write("Hello");
        $w->close;
    };
};

$app = Plack::Middleware::Session->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, "Hello";
    like $res->header('Set-Cookie'), qr/plack_session/;
};

done_testing;
