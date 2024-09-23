# NAME

Plack::Middleware::Session - Middleware for session management

# SYNOPSIS

    use Plack::Builder;

    my $app = sub {
        my $env = shift;
        my $session = $env->{'psgix.session'};
        return [
            200,
            [ 'Content-Type' => 'text/plain' ],
            [ "Hello, you've been here for ", $session->{counter}++, "th time!" ],
        ];
    };

    builder {
        enable 'Session';
        $app;
    };

    # Or, use the File store backend (great if you use multiprocess server)
    # For more options, see perldoc Plack::Session::Store::File
    builder {
        enable 'Session', store => 'File';
        $app;
    };

# DESCRIPTION

This is a Plack Middleware component for session management. By
default it will use cookies to keep session state and store data in
memory. This distribution also comes with other state and store
solutions. See perldoc for these backends how to use them.

It should be noted that we store the current session as a hash
reference in the `psgix.session` key inside the `$env` where you can
access it as needed.

**NOTE:** As of version 0.04 the session is stored in `psgix.session`
instead of `plack.session`.

## State

- [Plack::Session::State](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AState)

    This will maintain session state by passing the session through
    the request params. It does not do this automatically though,
    you are responsible for passing the session param.

- [Plack::Session::State::Cookie](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AState%3A%3ACookie)

    This will maintain session state using browser cookies.

## Store

- [Plack::Session::Store](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AStore)

    This is your basic in-memory session data store. It is volatile storage
    and not recommended for multiprocessing environments. However it is
    very useful for development and testing.

- [Plack::Session::Store::File](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AStore%3A%3AFile)

    This will persist session data in a file. By default it uses
    [Storable](https://metacpan.org/pod/Storable) but it can be configured to have a custom serializer and
    deserializer.

- [Plack::Session::Store::Cache](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AStore%3A%3ACache)

    This will persist session data using the [Cache](https://metacpan.org/pod/Cache) interface.

- [Plack::Session::Store::Null](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AStore%3A%3ANull)

    Sometimes you don't care about storing session data, in that case
    you can use this noop module.

# OPTIONS

The following are options that can be passed to this module.

- _state_

    This is expected to be an instance of [Plack::Session::State](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AState) or an
    object that implements the same interface. If no option is provided
    the default [Plack::Session::State::Cookie](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AState%3A%3ACookie) will be used.

- _store_

    This is expected to be an instance of [Plack::Session::Store](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AStore) or an
    object that implements the same interface. If no option is provided
    the default [Plack::Session::Store](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AStore) will be used.

    It should be noted that this default is an in-memory volatile store
    is only suitable for development (or single process servers). For a
    more robust solution see [Plack::Session::Store::File](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AStore%3A%3AFile) or
    [Plack::Session::Store::Cache](https://metacpan.org/pod/Plack%3A%3ASession%3A%3AStore%3A%3ACache).

# PLACK REQUEST OPTIONS

In addition to providing a `psgix.session` key in `$env` for
persistent session information, this module also provides a
`psgix.session.options` key which can be used to control the behavior
of the module per-request.  The following sub-keys exist:

- _change\_id_

    If set to a true value, forces the session identifier to change (rotate).  This
    should always be done after logging in, to prevent session fixation
    attacks from subdomains; see
    [http://en.wikipedia.org/wiki/Session\_fixation#Attacks\_using\_cross-subdomain\_cooking](http://en.wikipedia.org/wiki/Session_fixation#Attacks_using_cross-subdomain_cooking)

- _expire_

    If set to a true value, expunges the session from the store, and clears
    the state in the client.

- _no\_store_

    If set to a true value, no changes made to the session in this request
    will be saved to the store.  Either ["expire"](#expire) and ["change\_id"](#change_id) take
    precedence over this, as both need to update the session store.

- _late\_store_

    If set to a true value, the session will be saved at the _end_ of the
    request, after all data has been sent to the client -- this may be
    required if streaming responses attempt to alter the session after the
    header has already been sent to the client.  Note, however, that it
    introduces a possible race condition, where the server attempts to store
    the updated session before the client makes the next request.  For
    redirects, or other responses on which the client needs do minimal
    processing before making a second request, this race is quite possible
    to win -- causing the second request to obtain stale session data.

- _id_

    This key contains the session identifier of the session.  It should be
    considered read-only; to generate a new identifier, use ["change\_id"](#change_id).

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# AUTHOR

Tatsuhiko Miyagawa

Stevan Little <stevan.little@iinteractive.com>

# COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

[http://www.iinteractive.com](http://www.iinteractive.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
