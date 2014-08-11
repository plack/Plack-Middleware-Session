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

- [Plack::Session::State](https://metacpan.org/pod/Plack::Session::State)

    This will maintain session state by passing the session through
    the request params. It does not do this automatically though,
    you are responsible for passing the session param.

- [Plack::Session::State::Cookie](https://metacpan.org/pod/Plack::Session::State::Cookie)

    This will maintain session state using browser cookies.

## Store

- [Plack::Session::Store](https://metacpan.org/pod/Plack::Session::Store)

    This is your basic in-memory session data store. It is volatile storage
    and not recommended for multiprocessing environments. However it is
    very useful for development and testing.

- [Plack::Session::Store::File](https://metacpan.org/pod/Plack::Session::Store::File)

    This will persist session data in a file. By default it uses
    [Storable](https://metacpan.org/pod/Storable) but it can be configured to have a custom serializer and
    deserializer.

- [Plack::Session::Store::Cache](https://metacpan.org/pod/Plack::Session::Store::Cache)

    This will persist session data using the [Cache](https://metacpan.org/pod/Cache) interface.

- [Plack::Session::Store::Null](https://metacpan.org/pod/Plack::Session::Store::Null)

    Sometimes you don't care about storing session data, in that case
    you can use this noop module.

# OPTIONS

The following are options that can be passed to this module.

- _state_

    This is expected to be an instance of [Plack::Session::State](https://metacpan.org/pod/Plack::Session::State) or an
    object that implements the same interface. If no option is provided
    the default [Plack::Session::State::Cookie](https://metacpan.org/pod/Plack::Session::State::Cookie) will be used.

- _store_

    This is expected to be an instance of [Plack::Session::Store](https://metacpan.org/pod/Plack::Session::Store) or an
    object that implements the same interface. If no option is provided
    the default [Plack::Session::Store](https://metacpan.org/pod/Plack::Session::Store) will be used.

    It should be noted that this default is an in-memory volatile store
    is only suitable for development (or single process servers). For a
    more robust solution see [Plack::Session::Store::File](https://metacpan.org/pod/Plack::Session::Store::File) or
    [Plack::Session::Store::Cache](https://metacpan.org/pod/Plack::Session::Store::Cache).

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
