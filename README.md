# NAME

Plack::Session - Middleware for session management

# SYNOPSIS

    # Use with Middleware::Session
    enable "Session";

    # later in your app
    use Plack::Session;
    my $app = sub {
        my $env = shift;
        my $session = Plack::Session->new($env);

      $session->id;
      $session->get($key);
      $session->set($key, $value);
      $session->remove($key);
      $session->keys;

        $session->expire;
    };

# DESCRIPTION

This is the core session object, you probably want to look
at [Plack::Middleware::Session](http://search.cpan.org/perldoc?Plack::Middleware::Session), unless you are writing your
own session middleware component.

# METHODS

- __new ( $env )__

    The constructor takes a PSGI request env hash reference.

- __id__

    This is the accessor for the session id.

## Session Data Management

These methods allows you to read and write the session data like
Perl's normal hash.

- __get ( $key )__
- __set ( $key, $value )__
- __remove ( $key )__
- __keys__
- __session__, __dump__

## Session Lifecycle Management

- __expire__

    This method can be called to expire the current session id.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# AUTHOR

Stevan Little <stevan.little@iinteractive.com>

# COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

[http://www.iinteractive.com](http://www.iinteractive.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
