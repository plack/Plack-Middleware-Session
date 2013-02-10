use strict;
use warnings;
use inc::Module::Install;

name 'Plack-Middleware-Session';
all_from 'lib/Plack/Middleware/Session.pm';
license 'perl';

cpanfile;

tests_recursive;

WriteAll();
