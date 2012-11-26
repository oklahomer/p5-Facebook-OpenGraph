use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use URI;
use JSON::XS qw(encode_json decode_json);
use t::Util;

subtest 'user' => sub {
    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            app_id       => 123456789,
            secret       => 'foobarbuzz',
            access_token => 'dfasdfasdfasdfa',
        });
        my $datam = $fb->bulk_fetch([qw(4 go.hagiwara)]);
        
        ok $datam, 'response';
        is scalar @$datam, 2, 'number of objects';
        is $datam->[0]->{username}, 'zuck', 'username of 1st obj';
        is $datam->[1]->{username}, 'go.hagiwara', 'username of 2nd obj';

    } receive_request {

        my %args = @_;
        is_deeply $args{headers}, ['Authorization', 'OAuth dfasdfasdfasdfa'], 'headers';
        is $args{url}->as_string, 'https://graph.facebook.com/', 'end point';
        ok $args{content}, 'content';
        is $args{method}, 'POST', 'HTTP POST method';

        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => [
                +{
                    code    => 200,
                    headers => [
                        +{
                            name  => "Content-Type", 
                            value => "text/javascript; charset=UTF-8",
                        },
                    ],
                    body => encode_json(+{
                        link       => 'http://www.facebook.com/zuck',
                        name       => 'Mark Zuckerberg',
                        locale     => 'en_US',
                        username   => 'zuck',
                        last_name  => 'Zuckerberg',
                        id         => '4',
                        first_name => 'Mark',
                        gender     => 'male'
                    }),
                },
                +{
                    code    => 200,
                    headers => [
                        +{
                            name  => "Content-Type", 
                            value => "text/javascript; charset=UTF-8",
                        },
                    ],
                    body => encode_json(+{
                        link       => 'http://www.facebook.com/go.hagiwara',
                        name       => 'Go Hagiwara',
                        locale     => 'en_US',
                        username   => 'go.hagiwara',
                        last_name  => 'Hagiwara',
                        id         => '44007581',
                        first_name => 'Go',
                        gender     => 'male'
                    }),
                }
            ],
        };

    };
};

done_testing;
