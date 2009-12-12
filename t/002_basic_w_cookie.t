#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Plack::Request;
use Plack::Session;
use Plack::Session::State::Cookie;
use Plack::Session::Store;

use t::lib::TestSession;

t::lib::TestSession::run_all_tests(
    store           => Plack::Session::Store->new,
    state           => Plack::Session::State::Cookie->new,
    request_creator => sub {
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
    },
    response_test   => sub {
        my ($response, $session_id, $check_expired) = @_;
        is_deeply(
            $response->cookies,
            {
                plack_session => {
                    value => $session_id,
                    path  => '/',
                    ($check_expired
                        ? ( expires => '0' )
                        : ())
                }
            },
            '... got the right cookies in the response'
        );
    }
);

done_testing;
