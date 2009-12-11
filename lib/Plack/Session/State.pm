package Plack::Session::State;
use strict;
use warnings;

use Plack::Util::Accessor qw[
    generator
    extractor
    session_key
];

sub new {
    my ($class, %params) = @_;
    bless {
        session_key => $params{ session_key } || 'plack_session',
        generator   => do { my $id = 1; sub { $id++ } },
        extractor   => sub { $_[0]->param( $_[1] ) },
        expired     => {}
    } => $class;
}

sub expire_session_id {
    my ($self, $id) = @_;
    $self->{expired}->{ $id }++;
}

sub extract {
    my ($self, $request) = @_;
    my $id = $self->extractor->( $request, $self->session_key );
    return unless $id && not exists $self->{expired}->{ $id };
    return $id;
}

sub generate {
    my $self = shift;
    $self->generator->()
}

# given a request, get the
# session id from it
sub get_session_id {
    my ($self, $request) = @_;
    $self->extract( $request )
        ||
    $self->generate
}

1;