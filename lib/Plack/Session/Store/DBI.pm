package Plack::Session::Store::DBI;
use strict;
use warnings;

# XXX Is there a notion of auto-expiry?

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

use DBI;
use MIME::Base64 ();
use Storable ();

use parent 'Plack::Session::Store';

use Plack::Util::Accessor qw[ dbh table_name serializer deserializer ];

sub new {
    my ($class, %params) = @_;

    # XXX TODO: Somebody will most likely want to use a pre-cooked
    # dbh to be used as the database handle.

    my $connect_info = $params{connect_info};
    if (! $connect_info || ref $connect_info ne 'ARRAY' ) {
        die "DBI connect_info was not available, or is not an arrayref";
    }

    $params{table_name}   ||= 'sessions';
    $params{serializer}   ||= 
        sub { MIME::Base64::encode_base64( Storable::nfreeze( $_[0] ) ) };
    $params{deserializer} ||= 
        sub { Storable::thaw( MIME::Base64::decode_base64( $_[0] ) ) };

    my $self = bless { %params }, $class;
    $self->_prepare_dbh();
    return $self;
}

sub _prepare_dbh {
    my $self = shift;
    my $dbh = DBI->connect(@{ $self->{connect_info} });

    # These are pre-cooked, so we can efficiently execute them upon request
    my $table_name = $self->{table_name};
    my %sql = (
        get_session    =>
            "SELECT session_data FROM $table_name WHERE id = ?",

        delete_session =>
            "DELETE FROM $table_name WHERE id = ?",

        # XXX argument list order matters for insert and update!
        # (they should match, so we can execute them the same way)
        # If you change this, be sure to change store() as well.
        insert_session => 
            "INSERT INTO $table_name (session_data, id) VALUES (?, ?)",
        update_session =>
            "UPDATE $table_name SET session_data = ? WHERE id = ?",

        check_session => 
            "SELECT 1 FROM $table_name WHERE id = ?",
    );

    while (my ($name, $sql) = each %sql ) {
        $self->{"_sth_$name"} = $dbh->prepare($sql);
    }
}

sub fetch {
    my ($self, $session_id) = @_;
    my $sth = $self->{_sth_get_session};
    $sth->execute( $session_id );
    my ($data) = $sth->fetchrow_array();
    $sth->finish;
    return $data ? $self->deserializer->( $data ) : ();
}

sub store {
    my ($self, $session_id, $session) = @_;

    # XXX To be honest, I feel like there should be a transaction 
    # call here.... but Catalyst didn't have it, so I'm not so sure

    my $sth;

    $sth = $self->{_sth_check_session};
    $sth->execute($session_id);

    # need to fetch. on some DBD's execute()'s return status and
    # rows() is not reliable
    my ($exists) = $sth->fetchrow_array(); 

    $sth->finish;
    
    $sth = ($exists) ?
        $self->{_sth_update_session} : $self->{_sth_insert_session};

    $sth->execute( $self->serializer->($session), $session_id );
}

sub remove {
    my ($self, $session_id) = @_;
    my $sth = $self->{_sth_delete_session};
    $sth->execute( $session_id );
    $sth->finish;
}

1;

__END__

Your session table must have at least the following schema structure:

    CREATE TABLE sessions (
        id           CHAR(72) PRIMARY KEY,
        session_data TEXT
    );

Note that MySQL TEXT fields only store 64KB, so if your session data
will exceed that size you'll want to move to MEDIUMTEXT, MEDIUMBLOB,
or larger.
    

=head1 AUTHORS

Many aspects of this module were partially based upon Catalyst::Plugin::Session::Store::DBI

