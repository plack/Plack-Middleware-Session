#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Plack::Request;
use Plack::Session::State;
use Plack::Session::Store::Cache;

use lib "t/lib";
use TestSessionHash;

{
    package TestCache;

    sub new {
        my $class = shift;
        bless +{@_} => $class;
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
{
    package TestCacheMatchExpires;
    use base 'TestCache';

    sub set {
        my ($self, $key, $val, $expires ) = @_;

        Test::More::is $self->{expires} => $expires;
        $self->{$key} = $val;
    }
}
{
    package TestCacheDenyExpires;
    use base 'TestCache';

    sub set {
        my ($self, $key, $val, $expires ) = @_;

        Test::More::is $expires => undef;

        $self->{$key} = $val;
    }
}
{
    package TestCachePrefix;
    use base 'TestCache';


    sub set {
        my ($self, $key, $val ) = @_;

        Test::More::like $key, qr/^$self->{prefix}/;

        $self->{$key} = $val;
    }

    sub get {
        my ($self, $key ) = @_;

        Test::More::like $key, qr/^$self->{prefix}/;

        $self->{$key};
    }

    sub remove {
        my ($self, $key ) = @_;

        Test::More::like $key, qr/^$self->{prefix}/;

        delete $self->{$key};
    }
}

TestSessionHash::run_all_tests(
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

my $cache = TestCache->new;
t::lib::TestSessionHash::run_all_tests(
    store  => Plack::Session::Store::Cache->new( get_cache => sub { $cache } ),
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

t::lib::TestSessionHash::run_all_tests(
    store  => Plack::Session::Store::Cache->new( cache => TestCacheMatchExpires->new(expires => 111), expires => 111 ),
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

t::lib::TestSessionHash::run_all_tests(
    store  => Plack::Session::Store::Cache->new( cache => TestCacheDenyExpires->new ),
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

t::lib::TestSessionHash::run_all_tests(
    store  => Plack::Session::Store::Cache->new( cache => TestCachePrefix->new(prefix => 'test:'), prefix => 'test:' ),
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
