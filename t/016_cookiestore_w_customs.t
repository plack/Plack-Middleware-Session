use strict;
use Test::More;
use Test::Requires qw(Digest::HMAC_SHA1 YAML);
use Plack::Test;
use Plack::Middleware::Session::Cookie;
use HTTP::Request::Common;
use LWP::UserAgent;
use HTTP::Cookies;

$Plack::Test::Impl = 'Server';

my $app = sub {
    my $env = shift;
    my $session = $env->{'psgix.session'};

    my $counter = $session->{counter} || 0;
    if ($session->{counter}++ >= 2) {
        $env->{'psgix.session.options'}->{expire} = 1;
    }

    return [ 200, [], [ "counter=$counter" ] ];
};

$app = Plack::Middleware::Session::Cookie->wrap(
  $app,
  secret       => "foobar",
  expires      => 3600,
  serializer   => sub { MIME::Base64::encode(YAML::Dump($_[0])) },
  deserializer => sub { YAML::Load(MIME::Base64::decode($_[0])) },
);

my $ua = LWP::UserAgent->new;
$ua->cookie_jar( HTTP::Cookies->new );

test_psgi ua => $ua, app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, "counter=0";
    like $res->header('Set-Cookie'), qr/expires=/;
    like $res->header('Set-Cookie'), qr/path=\//;

    $res = $cb->(GET "/");
    is $res->content, "counter=1";
    like $res->header('Set-Cookie'), qr/expires=/;

    $res = $cb->(GET "/");
    is $res->content, "counter=2";

    $res = $cb->(GET "/");
    is $res->content, "counter=0";
};

done_testing;
