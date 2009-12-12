package Plack::Middleware::Session;
use strict;
use warnings;

use Plack::Session;
use Plack::Request;
use Plack::Response;
use Plack::Session::State::Cookie;
use Plack::Session::Store;

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw( state store );

sub prepare_app {
    my $self = shift;
    unless ($self->state) {
        $self->state( Plack::Session::State::Cookie->new );
    }

    unless ($self->store) {
        $self->store( Plack::Session::Store->new );
    }
}

sub call {
    my $self = shift;
    my $env  = shift;

    $env->{'plack.session'} = Plack::Session->new(
        state   => $self->state,
        store   => $self->store,
        request => Plack::Request->new( $env )
    );

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = Plack::Response->new(@{$_[0]});
        $env->{'plack.session'}->finalize( $res );
        @{$_[0]} = @{$res->finalize};
    });
}

1;

__END__

=pod

=head1 NAME

Plack::Middleware::Session - Middleware for session management

=head1 SYNOPSIS

  use Plack::Middleware::Session;

=head1 DESCRIPTION

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Tatsuhiko Miyagawa

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


