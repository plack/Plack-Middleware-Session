use strict;
use Plack::Test;
use Plack::Middleware::Session::Cookie;
use Test::More;
use HTTP::Request::Common;
use HTTP::Cookies;

my $app = sub {
    my $env = shift;

    $env->{'psgix.session'}->{counter} = 1;

    my $path = $env->{PATH_INFO} =~ /with_path/ ? "/foo" : undef;
    $env->{'psgix.session.options'}{path}   = $path;
    $env->{'psgix.session.options'}{domain} = '.example.com';

    return [ 200, [], [ "Hi" ] ];
};

$app = Plack::Middleware::Session::Cookie->wrap(
    $app,
    secret   => 'foobar',
    httponly => 1,
    samesite => 'Lax',
);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");
    like $res->header('Set-Cookie'), qr/plack_session=\S+; domain=.example.com; SameSite=Lax; HttpOnly/;

    $res = $cb->(GET "http://localhost/with_path");
    like $res->header('Set-Cookie'), qr/plack_session=\S+; domain=.example.com; path=\/foo; SameSite=Lax; HttpOnly/;
};

# Partitioned Cookies
# https://developer.mozilla.org/en-US/docs/Web/Privacy/Privacy_sandbox/Partitioned_cookies
$app = Plack::Middleware::Session::Cookie->wrap(
    $app,
    secret      => 'foobar',
    httponly    => 1,
    partitioned => 1
);

test_psgi $app, sub {
    my $cb = shift;

    # Partitioned cookies are secure, and always have SameSite=None
    # Lowercase "secure" provided by Cookie::Baker when using Partitioned.
    my $res = $cb->(GET "http://localhost/");
    like $res->header('Set-Cookie'), qr/plack_session=\S+; domain=.example.com; SameSite=None; secure; HttpOnly; Partitioned/;

    $res = $cb->(GET "http://localhost/with_path");
    like $res->header('Set-Cookie'), qr/plack_session=\S+; domain=.example.com; path=\/foo; SameSite=None; secure; HttpOnly; Partitioned/;
};

done_testing;

