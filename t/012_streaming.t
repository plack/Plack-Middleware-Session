use strict;
use File::Temp qw(tempdir);
use Test::More;
use Plack::Test;
use Plack::Middleware::Session;
use Plack::Session::Store::File;
use HTTP::Request::Common;

$Plack::Test::Impl = 'Server';

my $base_app = sub {
    my $env = shift;
    return sub {
        my $respond = shift;
        $env->{'psgix.session'}->{early} = 1;
        my $w = $respond->([ 200, [ 'Content-Type' => 'text/html' ] ]);
        $w->write("Hello");
        $env->{'psgix.session'}->{late} = 1;
        $w->close;
    };
};

my $tmp = tempdir(CLEANUP => 1);

my $store = Plack::Session::Store::File->new( dir => $tmp );
my $app = Plack::Middleware::Session->wrap( $base_app, store => $store);
test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, "Hello";
    like $res->header('Set-Cookie'), qr/plack_session/;

    my ($session_id) = $res->header('Set-Cookie') =~ /plack_session=([a-f0-9]+)/;
    ok $session_id, "Found session";
    my $session = $store->fetch($session_id);
    ok $session, "Fetched session $session_id";
    ok $session->{early}, "Early data is set";
    ok $session->{late}, "Late data is set";
};

done_testing;
