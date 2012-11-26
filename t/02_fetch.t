use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use URI;
use t::Util;

subtest 'user' => sub {
    send_request {

        my $fb = Facebook::OpenGraph->new;
        my $user = $fb->fetch('zuck');

        my $link = URI->new($user->{link});
        is $link->path, '/zuck', 'link';
        is $user->{id}, 4, 'id';
        is $user->{username}, 'zuck', 'username';
        ok !$user->{picture}, 'no picture';

    } receive_request {

        my %args = @_;
        is_deeply $args{headers}, [], 'no particular header';
        is $args{url}->as_string, 'https://graph.facebook.com/zuck', 'end point';
        is $args{content}, '', 'no content given';
        is $args{method}, 'GET', 'HTTP GET method';
        
        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => +{
                name       => 'Mark Zuckerberg',
                id         => 4,
                locale     => 'en_US',
                last_name  => 'Zuckerberg',
                username   => 'zuck',
                first_name => 'Mark',
                gender     => 'male',
                link       => 'http://www.facebook.com/zuck',
            },
        };

    };
};

subtest 'with fields' => sub {
    send_request {

        my $fb   = Facebook::OpenGraph->new;
        my $user = $fb->fetch('zuck', +{fields => 'picture'});

        is $user->{id}, 4, 'id';
        ok $user->{picture}, 'has picture';
        is $user->{picture}->{data}->{is_silhouette}, 'false', 'not silhouette';
        is $user->{picture}->{data}->{url}, 'http://profile.ak.fbcdn.net/hprofile-ak-prn1/157340_4_3955636_q.jpg';
    } receive_request {

        my %args = @_;
        is_deeply $args{headers}, [], 'no particular header';
        is $args{url}->as_string, 'https://graph.facebook.com/zuck?fields=picture', 'end point';
        is $args{content}, '', 'no content given';
        is $args{method}, 'GET', 'HTTP GET method';

        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => +{
                id      => 4,
                picture => +{
                    data => +{
                        is_silhouette => 'false',
                        url           => 'http://profile.ak.fbcdn.net/hprofile-ak-prn1/157340_4_3955636_q.jpg',
                    },
                },
            },
        };

    };
};

done_testing;
