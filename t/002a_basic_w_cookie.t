#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Plack::Request;
use Plack::Session::State::Cookie;
use Plack::Session::Store;
use Plack::Util;

use t::lib::TestSessionHash;

t::lib::TestSessionHash::run_all_tests(
    store  => Plack::Session::Store->new,
    state  => Plack::Session::State::Cookie->new,
    env_cb => sub {
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
    },
    response_test   => sub {
        my ($res_cb, $session_id, $check_expired) = @_;
        my $cookie;
        $res_cb->(sub {
            my $res = shift;
            $cookie = Plack::Util::header_get($res->[1], 'Set-Cookie');
        });

        like($cookie, qr/plack_session=$session_id/, '... cookie value is as suspected');
        if ($check_expired) {
            like($cookie, qr/expires=/, '... cookie is expriring as suspected');
        }
    }
);

done_testing;
