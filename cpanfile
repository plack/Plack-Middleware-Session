requires 'Plack'            => '0.9910';

# for session ID gen
requires 'Digest::SHA1'      => '0';
requires 'Digest::HMAC_SHA1' => '1.03';

# things the tests need
build_requires 'Test::More' => '0.88';
build_requires 'Test::Requires' => '0';
test_requires 'Test::Fatal', '0.006';
