#!/usr/bin/perl

use strict;
use warnings;
use Test::Requires 'CHI';

use Test::More;

use Plack::Request;
use Plack::Session;
use Plack::Session::State;
use Plack::Session::Store::CHI;

use t::lib::TestSession;

t::lib::TestSession::run_all_tests(
    store           => Plack::Session::Store::CHI->new( chi => CHI->new(driver => 'Memory', datastore => {}) ),
    state           => Plack::Session::State->new,
    request_creator => sub {
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
    },
);


done_testing;
