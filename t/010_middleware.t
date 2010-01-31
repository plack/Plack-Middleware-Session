use Plack::Test;
use Plack::Middleware::Session;
use Test::More;
use HTTP::Request::Common;
use HTTP::Cookies;

my $app = sub {
    my $env = shift;
    my $counter = $env->{'psgix.session'}->{counter} || 0;

    my $body = "Counter=$counter";
    $env->{'psgix.session'}->{counter} = $counter + 1;

    return [ 200, [ 'Content-Type', 'text/html' ], [ $body ] ];
};

$app = Plack::Middleware::Session->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $jar = HTTP::Cookies->new;

    my $res = $cb->(GET "http://localhost/");
    is $res->content_type, 'text/html';
    is $res->content, "Counter=0";
    $jar->extract_cookies($res);

    my $req = GET "http://localhost/";
    $jar->add_cookie_header($req);
    $res = $cb->($req);
    is $res->content, "Counter=1";
};

done_testing;

