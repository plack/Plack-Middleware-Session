use strict;
use warnings;
use inc::Module::Install;

name 'Plack-Middleware-Session';
all_from 'lib/Plack/Middleware/Session.pm';
license 'perl';

# prereqs
requires 'Plack'            => '0.9910';

# for session ID gen
requires 'Digest::SHA1'      => '0';

# things the tests need
build_requires 'Test::More' => '0.88';
build_requires 'Test::Requires' => '0';
test_requires 'Test::Exception';

tests_recursive;
auto_install;

WriteAll();

