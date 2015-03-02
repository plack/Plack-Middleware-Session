package Plack::Session::Cleanup;
use strict;
use warnings;

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:STEVAN';

sub new {
    my $class = shift;
    my $subref = shift;
    my $self = bless $subref, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->();
}

1;

__END__

=pod

=head1 NAME

Plack::Session::Cleanup - Run code when the environment is destroyed

=head1 SYNOPSIS

  $env->{'run_at_cleanup'} = Plack::Session::Cleanup->new(
      sub {
          # ...
      }
  );


=head1 DESCRIPTION

This provides a way for L<Plack::Middleware::Session> to run code when
the environment is cleaned up.

=head1 METHODS

=over 4

=item B<new ( $coderef )>

Executes the given code reference when the object is C<DESTROY>'d.  Care
should be taken that the given code reference does not close over
C<$env>, creating a cycle and preventing the C<$env> from being
destroyed.

=back

=cut
