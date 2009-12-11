package Plack::Session::Store;
use strict;
use warnings;

use Plack::Util::Accessor qw[ _stash ];

sub new { bless { _stash => {} } => shift }

sub fetch {
    my ($self, $session_id, $key) = @_;
    $self->_stash->{ $session_id }->{ $key }
}

sub store {
    my ($self, $session_id, $key, $data) = @_;
    $self->_stash->{ $session_id }->{ $key } = $data;
}

sub delete {
    my ($self, $session_id, $key) = @_;
    delete $self->_stash->{ $session_id }->{ $key };
}

sub persist {
    my ($self, $session_id) = @_;
    ()
}

sub cleanup {
    my ($self, $session_id) = @_;
    delete $self->_stash->{ $session_id }
}

1;