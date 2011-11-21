package t::lib::TestSessionHash;
use strict;
use warnings;

use Test::More;
use Test::Fatal qw(lives_ok);
use Plack::Middleware::Session;

sub create_session {
    my($mw, $env) = @_;

    my ($session, $session_options);
    my $app = sub {
        my $env = shift;
        $session         = $env->{'psgix.session'};
        $session_options = $env->{'psgix.session.options'};
        return sub {
            my $responder = shift;
            $responder->([ 200, [], [] ]);
        };
    };

    my $res = $mw->($app)->($env);

    return ($session, $session_options, $res);
}

sub run_all_tests {
    my %params = @_;

    my (
        $env_cb,
        $state,
        $storage,
        $response_test,
        $middleware_create_cb
    ) = @params{qw[
        env_cb
        state
        store
        response_test
        middleware_create_cb
    ]};

    my $m = $middleware_create_cb
          || sub { Plack::Middleware::Session->wrap($_[0], state => $state, store => $storage) };

    $response_test ||= sub {
        my($res_cb, $session_id, $check_expired) = @_;
        $res_cb->(sub { my $res = shift });
    };

    my @sids;
    {
        my($s, $opts, $res) = create_session($m, $env_cb->());

        push @sids, $opts->{id};

        ok(!$s->{'foo'}, '... no value stored in foo for session');

        lives_ok {
            $s->{foo} = 'bar';
        } '... set the value successfully in session';

        is($s->{'foo'}, 'bar', '... got the foo value back successfully from session');

        ok(!$s->{'bar'}, '... no value stored in foo for session');

        lives_ok {
            $s->{bar} = 'baz';
        } '... set the value successfully in session';

        is($s->{'bar'}, 'baz', '... got the foo value back successfully from session');

        is_deeply( $s, { foo => 'bar', bar => 'baz' }, '... got the session dump we expected');

        $response_test->($res, $sids[0]);
    }

    {
        my($s, $opts, $res) = create_session($m, $env_cb->());

        push @sids, $opts->{id};

        isnt($sids[0], $sids[1], "no same Session ID");
        ok(!$s->{'foo'}, '... no value stored for foo in session');

        lives_ok {
            $s->{foo} = 'baz';
        } '... set the value successfully';

        is($s->{'foo'}, 'baz', '... got the foo value back successfully from session');

        is_deeply( $s, { foo => 'baz' }, '... got the session dump we expected');

        $response_test->($res, $sids[1]);
    }

    {
        my($s, $opts, $res) = create_session($m, $env_cb->({ plack_session => $sids[0] }));
        is($opts->{id}, $sids[0], '... got a basic session id');

        is($s->{'foo'}, 'bar', '... got the value for foo back successfully from session');


        lives_ok {
            delete $s->{'foo'};
        } '... removed the foo value successfully from session';

        ok(!$s->{'foo'}, '... no value stored for foo in session');

        is_deeply( $s, { bar => 'baz' }, '... got the session dump we expected');

        $response_test->( $res, $sids[0] );
    }


    {
        my($s, $opts, $res) = create_session($m, $env_cb->({ plack_session => $sids[1] }));

        is($opts->{id}, $sids[1], '... got a basic session id');

        is($s->{'foo'}, 'baz', '... got the foo value back successfully from session');

        is_deeply( $s, { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $res, $sids[1] );
    }

    {
        my($s, $opts, $res) = create_session($m, $env_cb->({ plack_session => $sids[0] }));

        is($opts->{id}, $sids[0], '... got a basic session id');

        ok(!$s->{'foo'}, '... no value stored for foo in session');

        lives_ok {
            $s->{baz} = 'gorch';
        } '... set the bar value successfully in session';

        is_deeply( $s, { bar => 'baz', baz => 'gorch' }, '... got the session dump we expected');

        $response_test->( $res, $sids[0] );
    }

    {
        my($s, $opts, $res) = create_session($m, $env_cb->({ plack_session => $sids[0] }));

        is($s->{'bar'}, 'baz', '... got the bar value back successfully from session');

        lives_ok {
            $opts->{expire} = 1;
        } '... expired session successfully';

        $response_test->( $res, $sids[0], 1 );

        # XXX
        # this will not pass, because
        # it is just a hash ref and we are
        # not clearing it. Should we be?
        # - SL
        # is_deeply( $s, {}, '... got the session dump we expected');
    }

    {
        my($s, $opts, $res) = create_session($m, $env_cb->({ plack_session => $sids[0] }));

        push @sids, $opts->{id};
        isnt($opts->{id}, $sids[0], 'expired ... got a new session id');

        ok(!$s->{'bar'}, '... no bar value stored');

        is_deeply( $s, {}, '... got the session dump we expected');

        $response_test->( $res, $sids[2] );
    }

    {
        my($s, $opts, $res) = create_session($m, $env_cb->({ plack_session => $sids[1] }));

        is($opts->{id}, $sids[1], '... got a basic session id');

        is($s->{'foo'}, 'baz', '... got the foo value back successfully from session');

        is_deeply( $s, { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $res, $sids[1] );
    }

    {
        # wrong format session_id
        my($s, $opts, $res) = create_session($m, $env_cb->({ plack_session => "../wrong" }));

        isnt('../wrong' => $opts->{id}, '... regenerate session id');

        ok(!$s->{'foo'}, '... no value stored for foo in session');

        lives_ok {
            $s->{foo} = 'baz';
        } '... set the value successfully';

        is($s->{'foo'}, 'baz', '... got the foo value back successfully from session');

        is_deeply( $s, { foo => 'baz' }, '... got the session dump we expected');

        $response_test->( $res, $opts->{id} );
    }
}

1;
