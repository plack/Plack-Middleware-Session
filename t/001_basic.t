#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Plack::Request;

use Plack::Session;
use Plack::Session::State;
use Plack::Session::Store;

sub request {
    open my $in, '<', \do { my $d };
    my $env = {
        'psgi.version'    => [ 1, 0 ],
        'psgi.input'      => $in,
        'psgi.errors'     => *STDERR,
        'psgi.url_scheme' => 'http',
        SERVER_PORT       => 80,
        REQUEST_METHOD    => 'GET',
    };
    my $r = Plack::Request->new( $env );
    $r->parameters( @_ );
    $r;
}

my $storage = Plack::Session::Store->new;
my $state   = Plack::Session::State->new;

{
    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => request(),
    );

    is($s->id, 1, '... got a basic session id (1)');

    ok(!$s->get('foo'), '... no value stored in foo for session (1)');

    lives_ok {
        $s->set( foo => 'bar' );
    } '... set the value successfully in session (1)';

    is($s->get('foo'), 'bar', '... got the foo value back successfully from session (1)');

    lives_ok {
        $s->finalize;
    } '... finalized session (1) successfully';
}

{
    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => request(),
    );

    is($s->id, 2, '... got a basic session id (2)');

    ok(!$s->get('foo'), '... no value stored for foo in session (2)');

    lives_ok {
        $s->set( foo => 'baz' );
    } '... set the value successfully';

    is($s->get('foo'), 'baz', '... got the foo value back successfully from session (2)');

    lives_ok {
        $s->finalize;
    } '... finalized session (2) successfully';
}

{
    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => request({ plack_session => 1 }),
    );

    is($s->id, 1, '... got a basic session id (1)');

    is($s->get('foo'), 'bar', '... got the value for foo back successfully from session (1)');

    lives_ok {
        $s->remove( 'foo' );
    } '... removed the foo value successfully from session (1)';

    ok(!$s->get('foo'), '... no value stored for foo in session (1)');

    lives_ok {
        $s->finalize;
    } '... finalized session (1) successfully';
}


{
    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => request({ plack_session => 2 }),
    );

    is($s->id, 2, '... got a basic session id (2)');

    is($s->get('foo'), 'baz', '... got the foo value back successfully from session (2)');

    lives_ok {
        $s->finalize;
    } '... finalized session (2) successfully';
}

{
    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => request({ plack_session => 1 }),
    );

    is($s->id, 1, '... got a basic session id (1)');

    ok(!$s->get('foo'), '... no value stored for foo in session (1)');

    lives_ok {
        $s->set( bar => 'baz' );
    } '... set the bar value successfully in session (1)';

    lives_ok {
        $s->finalize;
    } '... finalized session (1) successfully';
}

{
    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => request({ plack_session => 1 }),
    );

    is($s->id, 1, '... got a basic session id (1)');

    is($s->get('bar'), 'baz', '... got the bar value back successfully from session (1)');

    lives_ok {
        $s->expire;
    } '... expired session (1) successfully';
}

{
    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => request({ plack_session => 1 }),
    );

    is($s->id, 3, '... got a new session id (3)');

    ok(!$s->get('bar'), '... no bar value stored (from session (1)) in session (3)');
}

{
    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => request({ plack_session => 2 }),
    );

    is($s->id, 2, '... got a basic session id (2)');

    is($s->get('foo'), 'baz', '... got the foo value back successfully from session (2)');

    lives_ok {
        $s->finalize;
    } '... finalized session (2) successfully';
}

done_testing;