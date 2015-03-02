package Plack::Session::Store::Null;
use strict;
use warnings;

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:STEVAN';

sub new     { bless {} => shift }
sub fetch   {}
sub store   {}
sub remove  {}

1;

__END__

=pod

=head1 NAME

Plack::Session::Store::Null - Null store

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;
  use Plack::Session::Store::Null;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session',
          store => Plack::Session::Store::Null->new;
      $app;
  };

=head1 DESCRIPTION

Sometimes you don't want to store anything in your sessions, but
L<Plack::Session> requires a C<store> instance, so you can use this
one and all methods will return null.

This is a subclass of L<Plack::Session::Store> and implements
its full interface.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

