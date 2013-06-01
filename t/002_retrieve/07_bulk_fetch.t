use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use URI;
use JSON 2 qw(encode_json decode_json);
use t::Util;

subtest 'user' => sub {

    my $zuck = +{
        link       => 'http://www.facebook.com/zuck',
        name       => 'Mark Zuckerberg',
        locale     => 'en_US',
        username   => 'zuck',
        last_name  => 'Zuckerberg',
        id         => '4',
        first_name => 'Mark',
        gender     => 'male'
    };

    my $hagiwara = +{
        link       => 'http://www.facebook.com/go.hagiwara',
        name       => 'Go Hagiwara',
        locale     => 'en_US',
        username   => 'go.hagiwara',
        last_name  => 'Hagiwara',
        id         => '44007581',
        first_name => 'Go',
        gender     => 'male'
    };

    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            app_id       => 123456789,
            secret       => 'foobarbuzz',
            access_token => 'dfasdfasdfasdfa',
        });
        my $data_ref = $fb->bulk_fetch([qw(4 go.hagiwara)]);
        
        is_deeply $data_ref, [$zuck, $hagiwara], 'data';

    } receive_request {

        my %args = @_;
        is_deeply(
            decode_json(delete $args{content}->{batch}),
            [
                +{
                    relative_url => 4,
                    method       => 'GET',
                },
                +{
                    relative_url => 'go.hagiwara',
                    method       => 'GET',
                },
            ],
            'batch'
        );
        is_deeply(
            \%args,
            +{
                headers => ['Authorization', 'OAuth dfasdfasdfasdfa'],
                url     => 'https://graph.facebook.com/',
                method  => 'POST',
                content => +{
                    access_token => 'dfasdfasdfasdfa',
                }
            },
            'args'
        );

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
                    body => encode_json($zuck),
                },
                +{
                    code    => 200,
                    headers => [
                        +{
                            name  => "Content-Type", 
                            value => "text/javascript; charset=UTF-8",
                        },
                    ],
                    body => encode_json($hagiwara),
                }
            ],
        };

    };
};

done_testing;
