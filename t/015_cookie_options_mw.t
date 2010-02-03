use strict;
use Plack::Test;
use Plack::Middleware::Session;
use Test::More;
use HTTP::Request::Common;
use HTTP::Cookies;

my $app = sub {
    my $env = shift;

    $env->{'psgix.session'}->{counter} = 1;

    my $path = $env->{PATH_INFO} =~ /with_path/ ? "/foo" : undef;
    $env->{'psgix.session.options'}{path}     = $path;
    $env->{'psgix.session.options'}{domain}   = '.example.com';
    $env->{'psgix.session.options'}{httponly} = 1;

    return [ 200, [], [ "Hi" ] ];
};

$app = Plack::Middleware::Session->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");
    like $res->header('Set-Cookie'), qr/plack_session=\w+; domain=.example.com; HttpOnly/;

    $res = $cb->(GET "http://localhost/with_path");
    like $res->header('Set-Cookie'), qr/plack_session=\w+; domain=.example.com; path=\/foo; HttpOnly/;
};

done_testing;

