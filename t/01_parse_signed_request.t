use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;

subtest 'signed_request' => sub {

    my $signed_request = "vlXgu64BQGFSQrY0ZcJBZASMvYvTHu9GQ0YM9rjPSso.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsIjAiOiJwYXlsb2FkIn0";
    my $fb = Facebook::OpenGraph->new(+{
        secret => 'secret'
    });
    my $datam = $fb->parse_signed_request($signed_request);
    my $expected_datam = +{
        0           => 'payload',
        'algorithm' => 'HMAC-SHA256',
    };

    is_deeply $datam, $expected_datam, 'datam';

};

done_testing;
