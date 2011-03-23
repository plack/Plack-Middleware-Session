#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);

use Test::Requires qw(DBI DBD::SQLite MIME::Base64 Storable);
use Test::More;

use Plack::Request;
use Plack::Session;
use Plack::Session::State::Cookie;
use Plack::Session::Store::DBI;

use t::lib::TestSession;

my $tmp  = tempdir(CLEANUP => 1);
my $file = File::Spec->catfile($tmp, "006_basic_w_dbi_store.db");
my $dbh  = DBI->connect( "dbi:SQLite:$file", undef, undef, {RaiseError => 1, AutoCommit => 1} );
$dbh->do(<<EOSQL);
CREATE TABLE sessions (
    id CHAR(72) PRIMARY KEY,
    session_data TEXT
);
EOSQL

t::lib::TestSession::run_all_tests(
    store  => Plack::Session::Store::DBI->new( dbh => $dbh ),
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

t::lib::TestSession::run_all_tests(
    store  => Plack::Session::Store::DBI->new( get_dbh => sub { $dbh }  ),
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


$dbh->disconnect;

done_testing;
