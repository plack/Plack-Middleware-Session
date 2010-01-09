use strict;
use Test::More;
use Test::Requires qw(Digest::HMAC_SHA1);
use Plack::Test;
use Plack::Middleware::Session::Cookie;
use HTTP::Request::Common;
use LWP::UserAgent;
use HTTP::Cookies;

$Plack::Test::Impl = 'Server';

my $app = sub {
    my $env = shift;
    my $session = $env->{'psgix.session'};

    my $counter = $session->get('counter') || 0;
    if ($counter >= 2) {
        $session->expire;
    } else {
        $session->set(counter => $counter + 1);
    }

    return [ 200, [], [ "counter=$counter" ] ];
};

$app = Plack::Middleware::Session::Cookie->wrap($app, secret => "foobar");

my $ua = LWP::UserAgent->new;
$ua->cookie_jar( HTTP::Cookies->new );

test_psgi ua => $ua, app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, "counter=0";

    $res = $cb->(GET "/");
    is $res->content, "counter=1";

    $res = $cb->(GET "/");
    is $res->content, "counter=2";

    my $res = $cb->(GET "/");
    is $res->content, "counter=0";
};

done_testing;
