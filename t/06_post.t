use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use t::Util;

subtest 'create test user' => sub {
    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            app_id => 1234556,
            secret => 'secret',
            access_token => '12345qwerty',
        });
        my $response = $fb->publish(
            $fb->app_id.'/accounts/test-users',
            +{
                installed   => 'true',
                permissions => 'read_stream',
            },
        );
        is $response->{id}, 123456789, 'user id';
        is $response->{access_token}, '5678uiop', 'access_token';
        is $response->{login_url}, 'https://www.facebook.com/platform/test_account_login?user_id=123456789&n=asdfghh', 'login_url';
        is $response->{email}, 'saffasdffad@tfbnw.net', 'user email';
        is $response->{password}, '67890', 'user password';

    } receive_request {

        my %args = @_;
        is_deeply $args{headers}, ['Authorization', 'OAuth 12345qwerty'], 'header';
        is_deeply $args{content}, +{permissions => 'read_stream', installed => 'true'}, 'content';
        is $args{url}->as_string, 'https://graph.facebook.com/1234556/accounts/test-users', 'end point';
        is $args{method}, 'POST', 'HTTP POST method';

        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => +{
                id           => 123456789,
                access_token => '5678uiop',
                login_url    => 'https://www.facebook.com/platform/test_account_login?user_id=123456789&n=asdfghh',
                email        => 'saffasdffad@tfbnw.net',
                password     => 67890,
            },
        };

    }
};

done_testing;
