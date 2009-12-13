package Plack::Session::Store::Null;
use strict;
use warnings;

sub new     { bless {} => shift }
sub fetch   {}
sub store   {}
sub delete  {}
sub cleanup {}
sub persist {}

1;

__END__

=pod

=head1 NAME

Plack::Session::Store::Null - Null store

=head1 DESCRIPTION

Sometimes you don't want to store anything in your sessions, but
L<Plack::Session> requires a C<store> instance, so you can use this
one and all methods will return null.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

