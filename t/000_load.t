#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( $_ ) || BAIL_OUT foreach qw[
    Plack::Middleware::Session
    Plack::Session
    Plack::Session::Store
    Plack::Session::Store::CHI
    Plack::Session::Store::File
    Plack::Session::State
    Plack::Session::State::Cookie
];

done_testing;