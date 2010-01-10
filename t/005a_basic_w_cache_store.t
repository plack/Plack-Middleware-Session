#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Plack::Request;
use Plack::Session::State;
use Plack::Session::Store::Cache;

use t::lib::TestSessionHash;

{
    package TestCache;

    sub new {
        bless {} => shift;
    }

    sub set {
        my ($self, $key, $val ) = @_;

        $self->{$key} = $val;
    }

    sub get {
        my ($self, $key ) = @_;

        $self->{$key};
    }

    sub remove {
        my ($self, $key ) = @_;

        delete $self->{$key};
    }
}

t::lib::TestSessionHash::run_all_tests(
    store  => Plack::Session::Store::Cache->new( cache => TestCache->new ),
    state  => Plack::Session::State->new,
    env_cb => sub {
        open my $in, '<', \do { my $d };
        my $env = {
            'psgi.version'    => [ 1, 0 ],
            'psgi.input'      => $in,
            'psgi.errors'     => *STDERR,
            'psgi.url_scheme' => 'http',
            SERVER_PORT       => 80,
            REQUEST_METHOD    => 'GET',
            QUERY_STRING      => join "&" => map { $_ . "=" . $_[0]->{ $_ } } keys %{$_[0] || +{}},
        };
    },
);


done_testing;
