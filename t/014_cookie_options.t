use strict;
use Test::More;

my $time = 1264843167;
BEGIN { *CORE::GLOBAL::time = sub() { $time } }
use Plack::Session::State::Cookie;

my $st = Plack::Session::State::Cookie->new;
$st->domain('.example.com');
$st->secure(1);
$st->expires(3600);
$st->path('/cgi-bin');

is_deeply +{ $st->merge_options(id => 123) },
  { domain => '.example.com', secure => 1, expires => $time + 3600, path => '/cgi-bin' };

is_deeply +{ $st->merge_options(id => 123, path => '/', domain => '.perl.org') },
  { domain => '.perl.org', secure => 1, expires => $time + 3600, path => '/' };

is_deeply +{ $st->merge_options(id => 123, expires => $time + 1, secure => 0, partitioned => 0) },
  { domain => '.example.com', secure => 0, expires => $time + 1, path => '/cgi-bin', partitioned => 0 };

is_deeply +{ $st->merge_options(id => 123, expires => $time + 1, secure => 0, partitioned => 1) },
  { domain => '.example.com', secure => 1, samesite => 'None', expires => $time + 1, path => '/cgi-bin', partitioned => 1 };

$st->partitioned(1);

is_deeply +{ $st->merge_options(id => 123, expires => $time + 1, secure => 0) },
  { domain => '.example.com', secure => 1, samesite => 'None', expires => $time + 1, path => '/cgi-bin', partitioned => 1 };


done_testing;
