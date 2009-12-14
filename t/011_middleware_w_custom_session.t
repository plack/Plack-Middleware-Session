use Plack::Test;
use Plack::Middleware::Session;
use Test::More;
use HTTP::Request::Common;
use HTTP::Cookies;

{
    package My::Custom::Session;
    use strict;
    use warnings;
    use parent 'Plack::Session';
}

my $app = sub {
    my $env = shift;

    isa_ok($env->{'plack.session'}, 'My::Custom::Session');

    my $counter = $env->{'plack.session'}->get('counter') || 0;

    my $body = "Counter=$counter";
    $counter++;
    $env->{'plack.session'}->set(counter => $counter);

    return [ 200, [], [ $body ] ];
};

$app = Plack::Middleware::Session->wrap(
    $app,
    session_class => 'My::Custom::Session'
);

test_psgi $app, sub {
    my $cb = shift;

    my $jar = HTTP::Cookies->new;

    my $res = $cb->(GET "http://localhost/");
    is $res->content, "Counter=0";
    $jar->extract_cookies($res);

    my $req = GET "http://localhost/";
    $jar->add_cookie_header($req);
    $res = $cb->($req);
    is $res->content, "Counter=1";
};

done_testing;

