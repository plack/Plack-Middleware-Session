use strict;
use warnings;
use inc::Module::Install;

name 'Plack-Middleware-Session';
all_from 'lib/Plack/Middleware/Session.pm';
license 'perl';

# prereqs
requires 'Plack'            => '0.9021';
requires 'Plack::Request'   => '0.09';

# for session ID gen
requires 'Digest::SHA1'      => '0';

# things the tests need
build_requires 'Test::More' => '0.88';
build_requires 'Test::Requires' => '0';

tests_recursive;
auto_install;

WriteAll();

