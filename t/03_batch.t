use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;
use URI;
use t::Util;
use JSON::XS qw(decode_json encode_json);

subtest 'w/out token' => sub {
        my $fb = Facebook::OpenGraph->new;
        my $batch_queries = [
            +{method => 'GET', relative_url => 'zuck'},
            +{method => 'GET', relative_url => 'Oklahomer'},
        ];
        throws_ok sub { $fb->batch($batch_queries); }, qr/Top level access_token must be set/, 'exception';

};

subtest 'w/ valid token' => sub {
    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            access_token => '123456789|XfSeFWB-0EQ0qyipMdmNpJEAuPk',
        });
        my $datam = $fb->batch([
            +{method => 'GET', relative_url => 'zuck'},
            +{method => 'GET', relative_url => 'Oklahomer'},
        ]);

        is_deeply(
            $datam,
            [
                +{
                    link       => 'http://www.facebook.com/zuck',
                    name       => 'Mark Zuckerberg',
                    locale     => 'en_US',
                    username   => 'zuck',
                    id         => 4,
                    first_name => 'Mark',
                    last_name  => 'Zuckerberg',
                    gender     => 'male',
                },
                +{
                    link => 'http://www.facebook.com/Oklahomer',
                    website => 'http://facebook-docs.oklahome.net/',
                    release_date => '2011-02-24',
                    name => 'Oklahomer',
                    description => 'Facebook etc....',
                    username => 'Oklahomer',
                    talking_about_count => 10390,
                    cover => {
                        source => 'http://sphotos-g.ak.fbcdn.net/hphotos-ak-snc6/s720x720/283711_500726406609334_431792850_n.jpg',
                        offset_y => 57,
                        cover_id => 500726406609334,
                    },
                    is_published => 'true',
                    category => 'Reference website',
                    about => 'http://facebook-docs.oklahome.net/',
                    id    => '204277149587596',
                    likes => 10126,
                }
            ],
            'datam'
        );

    } receive_request {

        my %args = @_;
        is $args{url}->as_string, 'https://graph.facebook.com/', 'url';
        is $args{method}, 'POST', 'HTTP POST method';
        is_deeply $args{headers}, ['Authorization', 'OAuth 123456789|XfSeFWB-0EQ0qyipMdmNpJEAuPk'], 'header';
        is_deeply(
            decode_json($args{content}->{batch}),
            [
                +{
                    relative_url => 'zuck',
                    method       => 'GET'
                },
                +{
                    relative_url => 'Oklahomer',
                    method       => 'GET'},
            ],
            'content'
        );

        return +{
            status  => 200,
            headers => [],
            message => 'OK',
            content => encode_json([
                +{
                    code => 200,
                    headers => [
                        +{
                            name  => "Access-Control-Allow-Origin",
                            value => "*"
                        },
                        +{
                            name  => "Cache-Control",
                            value => 'private, no-cache, no-store, must-revalidate'
                        },
                        +{
                            name  => "Connection",
                            value => "close"
                        },
                        +{
                            name => "Content-Type",
                            value => "text/javascript; charset=UTF-8"
                        },
                        +{
                            name => "ETag",
                            value => "539feb8a445c3d20a2ebacd02db380b27243b255"
                        },
                        +{
                            name => "Expires",
                            value => "Sat, 01 Jan 2000 00:00:00 GMT"
                        },
                        +{
                            name => "Pragma",
                            value => "no-cache"
                        }
                    ],
                    body => encode_json(+{
                        id         => 4,
                        name       => "Mark Zuckerberg",
                        first_name => "Mark",
                        last_name  => "Zuckerberg",
                        link => "http://www.facebook.com/zuck",
                        username => "zuck",
                        gender => "male",
                        locale => "en_US"
                    }),
                },
                {
                    code => 200,
                    headers => [
                        +{
                            name => "Access-Control-Allow-Origin",
                            value => "*"
                        },
                        +{
                            name => "Cache-Control",
                            value => "private, no-cache, no-store, must-revalidate"
                        },
                        +{
                            name => "Connection",
                            value => "close"
                        },
                        +{
                            name => "Content-Type",
                            value => "text/javascript; charset=UTF-8"
                        },
                        +{
                            name => "ETag",
                            value => "2b6e34285cc05942f8ddd4f8abec7b66c6493184"
                        },
                        +{
                            name => "Expires",
                            value => "Sat, 01 Jan 2000 00:00:00 GMT"
                        },
                        +{
                            name => "Pragma",
                            value => "no-cache"
                        }
                    ],
                    body => encode_json(+{
                        name => "Oklahomer",
                        is_published => "true",
                        website => "http://facebook-docs.oklahome.net/",
                        username => "Oklahomer",
                        description => "Facebook etc....",
                        about => "http://facebook-docs.oklahome.net/",
                        release_date => "2011-02-24",
                        talking_about_count => 10390,
                        category => "Reference website",
                        id => 204277149587596,
                        link => "http://www.facebook.com/Oklahomer",
                        likes => 10126,
                        cover => +{
                            cover_id => 500726406609334,
                            source   => "http://sphotos-g.ak.fbcdn.net/hphotos-ak-snc6/s720x720/283711_500726406609334_431792850_n.jpg",
                            offset_y => 57
                        },
                    }),
                }
            ]),
        }
    }
    
};

done_testing;
