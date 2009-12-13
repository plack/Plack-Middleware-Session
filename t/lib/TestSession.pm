package t::lib::TestSession;
use strict;
use warnings;

use Test::More;
use Test::Exception;

sub run_all_tests {
    my %params = @_;

    my (
        $request_creator,
        $state,
        $storage,
        $response_test
    ) = @params{qw[
        request_creator
        state
        store
        response_test
    ]};

    $response_test = sub {
        my ($response, $session_id, $check_expired) = @_;
    };

    my @sids;
    {
        my $r = $request_creator->();

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );

        push @sids, $s->id;

        ok(!$s->get('foo'), '... no value stored in foo for session');

        lives_ok {
            $s->set( foo => 'bar' );
        } '... set the value successfully in session';

        is($s->get('foo'), 'bar', '... got the foo value back successfully from session');

        ok(!$s->get('bar'), '... no value stored in foo for session');

        lives_ok {
            $s->set( bar => 'baz' );
        } '... set the value successfully in session';

        is($s->get('bar'), 'baz', '... got the foo value back successfully from session');

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $sids[0] ), { foo => 'bar', bar => 'baz' }, '... got the session dump we expected');

        $response_test->( $resp, $sids[0] );
    }

    {
        my $r = $request_creator->();

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );

        push @sids, $s->id;

        isnt($sids[0], $sids[1], "no same Session ID");
        ok(!$s->get('foo'), '... no value stored for foo in session');

        lives_ok {
            $s->set( foo => 'baz' );
        } '... set the value successfully';

        is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $sids[1] ), { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $resp, $sids[1] );
    }

    {
        my $r = $request_creator->({ plack_session => $sids[0] });

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );

        is($s->id, $sids[0], '... got a basic session id');

        is($s->get('foo'), 'bar', '... got the value for foo back successfully from session');

        lives_ok {
            $s->remove( 'foo' );
        } '... removed the foo value successfully from session';

        ok(!$s->get('foo'), '... no value stored for foo in session');

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $sids[0] ), { bar => 'baz' }, '... got the session dump we expected');

        $response_test->( $resp, $sids[0] );
    }


    {
        my $r = $request_creator->({ plack_session => $sids[1] });

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );

        is($s->id, $sids[1], '... got a basic session id');

        is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $sids[1] ), { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $resp, $sids[1] );
    }

    {
        my $r = $request_creator->({ plack_session => $sids[0] });

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );

        is($s->id, $sids[0], '... got a basic session id');

        ok(!$s->get('foo'), '... no value stored for foo in session');

        lives_ok {
            $s->set( baz => 'gorch' );
        } '... set the bar value successfully in session';

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $sids[0] ), { bar => 'baz', baz => 'gorch' }, '... got the session dump we expected');

        $response_test->( $resp, $sids[0] );
    }

    {
        my $r = $request_creator->({ plack_session => $sids[0] });

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );

        is($s->get('bar'), 'baz', '... got the bar value back successfully from session');

        lives_ok {
            $s->expire;
        } '... expired session successfully';

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $sids[0] ), {}, '... got the session dump we expected');

        $response_test->( $resp, $sids[0], 1 );
    }

    {
        my $r = $request_creator->({ plack_session => $sids[0] });

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );

        push @sids, $s->id;
        isnt($s->id, $sids[0], 'expired ... got a new session id');

        ok(!$s->get('bar'), '... no bar value stored');

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $sids[2] ), {}, '... got the session dump we expected');

        $response_test->( $resp, $sids[2] );
    }

    {
        my $r = $request_creator->({ plack_session => $sids[1] });

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );

        is($s->id, $sids[1], '... got a basic session id');

        is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $sids[1] ), { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $resp, $sids[1] );
    }

    {
        # wrong format session_id
        my $r = $request_creator->({ plack_session => '../wrong' });

        my $s = Plack::Session->new(
            state   => $state,
            store   => $storage,
            request => $r,
        );


        isnt('../wrong' => $s->id, '... regenerate session id');

        ok(!$s->get('foo'), '... no value stored for foo in session');

        lives_ok {
            $s->set( foo => 'baz' );
        } '... set the value successfully';

        is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

        my $resp = $r->new_response;

        lives_ok {
            $s->finalize( $resp );
        } '... finalized session successfully';

        is_deeply( $s->store->dump_session( $s->id ), { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $resp, $s );
    }
}

1;
