use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use t::Util;
use JSON 2 qw(encode_json);

subtest 'create test user' => sub {

    my $data_ref = [
        +{
            id           => 123456789,
            access_token => '5678uiop',
            login_url    => 'https://www.facebook.com/platform/test_account_login?user_id=123456789&n=asdfghh',
            email        => 'saffasdffad@tfbnw.net',
            password     => 67890,
        },
        +{
            id           => 1234567890,
            access_token => '5678uiopasadfasdfa',
            login_url    => 'https://www.facebook.com/platform/test_account_login?user_id=1234567890&n=asdfghdasdfash',
            email        => 'asdfghdasdfash@tfbnw.net',
            password     => 12345,
        },
    ];

    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            app_id => 1234556,
            secret => 'secret',
            access_token => '12345qwerty',
        });
        my $res = $fb->create_test_users([
            +{
                permissions => [qw/publish_actions/],
                locale      => 'en_US',
                installed   => 'true',
            },
            +{
                permissions => [qw/publish_actions email read_stream/],
                locale      => 'ja_JP', 
                installed   => 'true',
            },
        ]);
        is_deeply $res, $data_ref, 'data';

    } receive_request {

        my %args = @_;
        is $args{url}, 'https://graph.facebook.com/', 'end point';
        is $args{method}, 'POST', 'method';
        is_deeply $args{headers}, ['Authorization', 'OAuth 12345qwerty'], 'headers';

        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => encode_json([
                +{
                    code    => 200,
                    headers => [],
                    body    => encode_json($data_ref->[0]),
                },
                +{
                    code    => 200,
                    headers => [],
                    body    => encode_json($data_ref->[1]),
                }
            ]),
        };

    }
};

done_testing;
