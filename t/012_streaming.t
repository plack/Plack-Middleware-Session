use strict;
use File::Temp qw(tempdir);
use Test::More;
use Plack::Test;
use Plack::Middleware::Session;
use Plack::Session::Store::File;
use HTTP::Request::Common;
use LWP::UserAgent;
use HTTP::Cookies;

$Plack::Test::Impl = 'Server';

my $base_app = sub {
    my $env = shift;
    return sub {
        my $respond = shift;

        # Enable late storage on the second request
        $env->{'psgix.session.options'}->{late_store} = 1
            if $env->{'psgix.session'}->{early};

        $env->{'psgix.session'}->{early}++;
        my $w = $respond->([ 200, [ 'Content-Type' => 'text/html' ] ]);
        $w->write("Hello");
        $env->{'psgix.session'}->{late}++;
        $w->close;
    };
};

my $tmp = tempdir(CLEANUP => 1);
my $store = Plack::Session::Store::File->new( dir => $tmp );
my $app = Plack::Middleware::Session->wrap( $base_app, store => $store);

my $ua = LWP::UserAgent->new;
$ua->cookie_jar( HTTP::Cookies->new );
test_psgi ua => $ua, app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, "Hello";
    like $res->header('Set-Cookie'), qr/plack_session/;

    my ($session_id) = $res->header('Set-Cookie') =~ /plack_session=([a-f0-9]+)/;
    ok $session_id, "Found session";
    my $session = $store->fetch($session_id);
    ok $session, "Fetched session $session_id";
    is $session->{early}, 1, "Early data is set";
    is $session->{late}, undef, "Late data was lost, as late_store was not set";

    $res = $cb->(GET "/");
    is $res->content, "Hello";
    like $res->header('Set-Cookie'), qr/plack_session/;
    $session = $store->fetch($session_id);
    ok $session, "Fetched session $session_id";
    is $session->{early}, 2, "Early data is set";
    is $session->{late}, 1, "Late data was stored";
};

done_testing;
