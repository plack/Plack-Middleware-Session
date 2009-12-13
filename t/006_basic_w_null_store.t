#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Plack::Request;
use Plack::Session;
use Plack::Session::State;
use Plack::Session::Store::Null;

my $storage         = Plack::Session::Store::Null->new;
my $state           = Plack::Session::State->new;
my $request_creator = sub {
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
};

{
    my $r = $request_creator->();

    my $s = Plack::Session->new(
        state   => $state,
        store   => $storage,
        request => $r,
    );

    ok($s->id, '... got a session id');

    ok(!$s->get('foo'), '... no value stored in foo for session');

    lives_ok {
        $s->set( foo => 'bar' );
    } '... set the value successfully in session';

    ok(!$s->get('foo'), '... still no value stored in foo for session (null store)');

    lives_ok {
        $s->remove('foo');
    } '... removed the value successfully in session';

    lives_ok {
        $s->expire;
    } '... expire session successfully';

    my $resp = $r->new_response;

    lives_ok {
        $s->finalize( $resp );
    } '... finalized session successfully';
}


done_testing;
