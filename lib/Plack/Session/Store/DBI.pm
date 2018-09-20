package Plack::Session::Store::DBI;
use strict;
use warnings;

# XXX Is there a notion of auto-expiry?

our $VERSION   = '0.33';
our $AUTHORITY = 'cpan:STEVAN';

use MIME::Base64 ();
use Storable ();

use parent 'Plack::Session::Store';

use Plack::Util::Accessor qw[ dbh get_dbh table_name serializer deserializer id_column data_column];

sub new {
    my ($class, %params) = @_;

    if (! $params{dbh} && ! $params{get_dbh}) {
        die "DBI instance or a callback was not available in the argument list";
    }

    $params{table_name}   ||= 'sessions';
    $params{data_column}  ||= 'session_data';
    $params{id_column}    ||= 'id';
    $params{serializer}   ||= 
        sub { MIME::Base64::encode_base64( Storable::nfreeze( $_[0] ) ) };
    $params{deserializer} ||= 
        sub { Storable::thaw( MIME::Base64::decode_base64( $_[0] ) ) };

    my $self = bless { %params }, $class;
    return $self;
}

sub _dbh {
    my $self =shift;
    ( exists $self->{get_dbh} ) ? $self->{get_dbh}->() : $self->{dbh};
}

sub fetch {
    my ($self, $session_id) = @_;
    my $table_name = $self->{table_name};
    my $data_column = $self->{data_column};
    my $id_column = $self->{id_column};
    my $dbh = $self->_dbh;
    my $sth = $dbh->prepare_cached(
        sprintf(
            "SELECT %s FROM %s WHERE %s = ?",
            $dbh->quote_identifier($data_column),
            $dbh->quote_identifier($table_name),
            $dbh->quote_identifier($id_column),
        )
    );
    $sth->execute( $session_id );
    my ($data) = $sth->fetchrow_array();
    $sth->finish;
    return $data ? $self->deserializer->( $data ) : ();
}

sub store {
    my ($self, $session_id, $session) = @_;
    my $table_name = $self->{table_name};
    my $data_column = $self->{data_column};
    my $id_column = $self->{id_column};

    my $dbh = $self->_dbh;

    # XXX To be honest, I feel like there should be a transaction 
    # call here.... but Catalyst didn't have it, so I'm not so sure

    my $sth = $dbh->prepare_cached(
        sprintf(
            "SELECT 1 FROM %s WHERE %s = ?",
            $dbh->quote_identifier($table_name),
            $dbh->quote_identifier($id_column),
        )
    );
    $sth->execute($session_id);

    # need to fetch. on some DBD's execute()'s return status and
    # rows() is not reliable
    my ($exists) = $sth->fetchrow_array(); 

    $sth->finish;

    my %column_data = (
        $self->additional_column_data($session),

        $data_column => $self->serializer->($session),
        $id_column => $session_id,
    );
    
    my @columns = sort keys %column_data;
    if ($exists) {
        my $sth = $dbh->prepare_cached(
            sprintf(
                "UPDATE %s SET %s WHERE %s = ?",
                $dbh->quote_identifier($table_name),
                join(',', map { $dbh->quote_identifier($_).' = ?' } @columns),
                $dbh->quote_identifier($id_column),
            )
        );
        $sth->execute( @column_data{@columns}, $session_id );
    }
    else {
        my $sth = $dbh->prepare_cached(
            sprintf(
                "INSERT INTO %s (%s) VALUES (%s)",
                $dbh->quote_identifier($table_name),
                join(',', map { $dbh->quote_identifier($_) } @columns),
                join(',', map { '?' } @columns),
            )
         );
        $sth->execute( @column_data{@columns});
    }
}

sub additional_column_data { }

sub remove {
    my ($self, $session_id) = @_;
    my $table_name = $self->{table_name};
    my $id_column = $self->{id_column};
    my $sth = $self->_dbh->prepare_cached(
        sprintf(
            "DELETE FROM %s WHERE %s = ?",
            $self->_dbh->quote_identifier($table_name),
            $self->_dbh->quote_identifier($id_column),
        )
    );
    $sth->execute( $session_id );
    $sth->finish;
}

1;

__END__

=head1 NAME

Plack::Session::Store::DBI - DBI-based session store

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;
  use Plack::Session::Store::DBI;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Session',
          store => Plack::Session::Store::DBI->new(
              dbh => DBI->connect( @connect_args )
          );
      $app;
  };

  # set get_dbh callback for ondemand

  builder {
      enable 'Session',
          store => Plack::Session::Store::DBI->new(
              get_dbh => sub { DBI->connect( @connect_args ) }
          );
      $app;
  };
  
  # with custom serializer/deserializer

  builder {
      enable 'Session',
          store => Plack::Session::Store::DBI->new(
              dbh => DBI->connect( @connect_args )
              # YAML takes its args in the opposite order
              serializer   => sub { YAML::DumpFile( reverse @_ ) },
              deserializer => sub { YAML::LoadFile( @_ ) },
          );
      $app;
  };


  # use custom session table name, session ID or data columns

  builder {
      enable 'Session',
          store => Plack::Session::Store::DBI->new(
              dbh         => DBI->connect( @connect_args ),
              table_name  => 'my_session_table',
              id_column   => 'session_id',
              data_column => 'data',
          );
      $app;
  };

=head1 DESCRIPTION

This implements a DBI based storage for session data. By
default it will use L<Storable> and L<MIME::Base64> to serialize and 
deserialize the data, but this can be configured easily. 

This is a subclass of L<Plack::Session::Store> and implements
its full interface.

=head1 SESSION TABLE SCHEMA

Your session table must have at least the following schema structure:

    CREATE TABLE sessions (
        id           CHAR(72) PRIMARY KEY,
        session_data TEXT
    );

Note that MySQL TEXT fields only store 64KB, so if your session data
will exceed that size you'll want to move to MEDIUMTEXT, MEDIUMBLOB,
or larger.

You can opt to specify alternative table names (using table_name), as well as
alternative columns to use for session ID (id_column) and session data storage
(data_column), especially useful if you're converting from an existing session
mechanism.

=head1 EXTENDING

Plack::Session::Store::DBI has built in functionality to allow for inheriting
modules to set additional columns on each session row.

By overriding the additional_column_data function, you can return a hash of
columns and values to set.  The session data hashref will be passed to the
overridden additional_column_data function as its only argument, so that you
can use session data values as appropriate for any additional column data you
would like to set.

=head1 AUTHORS

Many aspects of this module were partially based upon L<Catalyst::Plugin::Session::Store::DBI>

Daisuke Maki

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Daisuke Maki C<< <daisuke@endeworks.jp> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
=cut

