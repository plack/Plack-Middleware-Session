package t::lib::TestSession;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Plack::Middleware::Session;
use Plack::Session;

sub create_session {
    my($mw, $env) = @_;

    my $session;
    my $app = sub {
        my $env = shift;
        $session = Plack::Session->new($env);
        return sub {
            my $responder = shift;
            $responder->([ 200, [], [] ]);
        };
    };

    my $res = $mw->($app)->($env);

    return ($session, $res);
}

sub run_all_tests {
    my %params = @_;

    my (
        $env_cb,
        $state,
        $storage,
        $response_test
    ) = @params{qw[
        env_cb
        state
        store
        response_test
    ]};

    my $m = sub { Plack::Middleware::Session->wrap($_[0], state => $state, store => $storage) };

    $response_test ||= sub {
        my($res_cb, $session_id, $check_expired) = @_;
        $res_cb->(sub { my $res = shift });
    };

    my @sids;
    {
        my($s, $res) = create_session($m, $env_cb->());

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

        is_deeply( $s->dump, { foo => 'bar', bar => 'baz' }, '... got the session dump we expected');

        $response_test->($res, $sids[0]);
    }

    {
        my($s, $res) = create_session($m, $env_cb->());

        push @sids, $s->id;

        isnt($sids[0], $sids[1], "no same Session ID");
        ok(!$s->get('foo'), '... no value stored for foo in session');

        lives_ok {
            $s->set( foo => 'baz' );
        } '... set the value successfully';

        is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

        is_deeply( $s->dump, { foo => 'baz' }, '... got the session dump we expected');

        $response_test->($res, $sids[1]);
    }

    {
        my($s, $res) = create_session($m, $env_cb->({ plack_session => $sids[0] }));
        is($s->id, $sids[0], '... got a basic session id');

        is($s->get('foo'), 'bar', '... got the value for foo back successfully from session');


        lives_ok {
            $s->remove( 'foo' );
        } '... removed the foo value successfully from session';

        ok(!$s->get('foo'), '... no value stored for foo in session');

        is_deeply( $s->dump, { bar => 'baz' }, '... got the session dump we expected');

        $response_test->( $res, $sids[0] );
    }


    {
        my($s, $res) = create_session($m, $env_cb->({ plack_session => $sids[1] }));

        is($s->id, $sids[1], '... got a basic session id');

        is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

        is_deeply( $s->dump, { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $res, $sids[1] );
    }

    {
        my($s, $res) = create_session($m, $env_cb->({ plack_session => $sids[0] }));

        is($s->id, $sids[0], '... got a basic session id');

        ok(!$s->get('foo'), '... no value stored for foo in session');

        lives_ok {
            $s->set( baz => 'gorch' );
        } '... set the bar value successfully in session';

        is_deeply( $s->dump, { bar => 'baz', baz => 'gorch' }, '... got the session dump we expected');

        $response_test->( $res, $sids[0] );
    }

    {
        my($s, $res) = create_session($m, $env_cb->({ plack_session => $sids[0] }));

        is($s->get('bar'), 'baz', '... got the bar value back successfully from session');

        lives_ok {
            $s->expire;
        } '... expired session successfully';

        $response_test->( $res, $sids[0], 1 );

        is_deeply( $s->dump, {}, '... got the session dump we expected');
    }

    {
        my($s, $res) = create_session($m, $env_cb->({ plack_session => $sids[0] }));

        push @sids, $s->id;
        isnt($s->id, $sids[0], 'expired ... got a new session id');

        ok(!$s->get('bar'), '... no bar value stored');

        is_deeply( $s->dump, {}, '... got the session dump we expected');

        $response_test->( $res, $sids[2] );
    }

    {
        my($s, $res) = create_session($m, $env_cb->({ plack_session => $sids[1] }));

        is($s->id, $sids[1], '... got a basic session id');

        is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

        is_deeply( $s->dump, { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $res, $sids[1] );
    }

    {
        # wrong format session_id
        my($s, $res) = create_session($m, $env_cb->({ plack_session => "../wrong" }));

        isnt('../wrong' => $s->id, '... regenerate session id');

        ok(!$s->get('foo'), '... no value stored for foo in session');

        lives_ok {
            $s->set( foo => 'baz' );
        } '... set the value successfully';

        is($s->get('foo'), 'baz', '... got the foo value back successfully from session');

        is_deeply( $s->dump, { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $res, $s->id );
    }
}

1;
