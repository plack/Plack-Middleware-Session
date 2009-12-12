#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Plack::Request;

use Plack::Session;
use Plack::Session::State::Cookie;
use Plack::Session::Store;

sub request {
    my $cookies = shift;
    open my $in, '<', \do { my $d };
    my $env = {
        'psgi.version'    => [ 1, 0 ],
        'psgi.input'      => $in,
        'psgi.errors'     => *STDERR,
        'psgi.url_scheme' => 'http',
        SERVER_PORT       => 80,
        REQUEST_METHOD    => 'GET',
        HTTP_COOKIE       => join "; " => map { $_ . "=" . $cookies->{ $_ } } keys %$cookies,
    };
    return Plack::Request->new( $env );
}

my $storage = Plack::Session::Store->new;
my $state   = Plack::Session::State::Cookie->new;

my @sids;
{
    my $r = request();

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    push @sids, $s->id;

    ok(!$s->get('foo'), '... no value stored in foo for session');

    lives_ok {
        $s->set( foo => 'bar' );
    } '... set the value successfully in session';

    is($s->get('foo'), 'bar', '... got the foo value back successfully from session');

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';

    is_deeply(
        $resp->cookies,
        {
            plack_session => {
                value => $sids[0],
                path  => '/'
            }
        },
        '... got the right cookies in the response'
    );
}

{
    my $r = request();

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    push @sids, $s->id;

    isnt($sids[0], $sids[1], "... not the same session id");
    ok(!$s->get('foo'), '... no value stored for foo in session');

    lives_ok {
        $s->set( foo => 'baz' );
    } '... set the value successfully';

    is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';

    is_deeply(
        $resp->cookies,
        {
            plack_session => {
                value => $sids[1],
                path  => '/'
            }
        },
        '... got the right cookies in the response'
    );
}

{
    my $r = request({ plack_session => $sids[0] });

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    is($s->id, $sids[0], '... got a basic session id');

    is($s->get('foo'), 'bar', '... got the value for foo back successfully from session');

    lives_ok {
        $s->remove( 'foo' );
    } '... removed the foo value successfully from session';

    ok(!$s->get('foo'), '... no value stored for foo in session');

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';

    is_deeply(
        $resp->cookies,
        {
            plack_session => {
                value => $sids[0],
                path  => '/'
            }
        },
        '... got the right cookies in the response'
    );
}

{
    my $r = request({ plack_session => $sids[1] });

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    is($s->id, $sids[1], '... got a basic session id');

    is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';

    is_deeply(
        $resp->cookies,
        {
            plack_session => {
                value => $sids[1],
                path  => '/'
            }
        },
        '... got the right cookies in the response'
    );
}

{
    my $r = request({ plack_session => $sids[0] });

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    is($s->id, $sids[0], '... got a basic session id');

    ok(!$s->get('foo'), '... no value stored for foo in session');

    lives_ok {
        $s->set( bar => 'baz' );
    } '... set the bar value successfully in session';

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';

    is_deeply(
        $resp->cookies,
        {
            plack_session => {
                value => $sids[0],
                path  => '/'
            }
        },
        '... got the right cookies in the response'
    );
}

{
    my $r = request({ plack_session => $sids[0] });

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    is($s->get('bar'), 'baz', '... got the bar value back successfully from session');

    lives_ok {
        $s->expire;
    } '... expired session successfully';

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';

    is_deeply(
        $resp->cookies,
        {
            plack_session => {
                value   => $sids[0],
                path    => '/',
                expires => '0'
            }
        },
        '... got the right cookies in the response'
    );
}

{
    my $r = request({ plack_session => $sids[0] });

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    push @sids, $s->id;
    isnt($s->id, $sids[0], 'expired ... got a new session id');

    ok(!$s->get('bar'), '... no bar value stored');

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';

    is_deeply(
        $resp->cookies,
        {
            plack_session => {
                value   => $sids[2],
                path    => '/',
            }
        },
        '... got the right cookies in the response'
    );
}

{
    my $r = request({ plack_session => $sids[1] });

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    is($s->id, $sids[1], '... got a basic session id');

    is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';

    is_deeply(
        $resp->cookies,
        {
            plack_session => {
                value   => $sids[1],
                path    => '/',
            }
        },
        '... got the right cookies in the response'
    );
}

done_testing;
