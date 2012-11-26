use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use t::Util;

use Data::Dumper;
subtest 'etag' => sub {
    send_request {

        my $fb = Facebook::OpenGraph->new;
        my $user = $fb->fetch_with_etag('zuck', +{}, '539feb8aee5c3d20a2ebacd02db380b27243b255');
        is $user, undef, 'not modified';

    } receive_request {

        my %args = @_;
        is_deeply $args{headers}, [qw/IF-None-Match 539feb8aee5c3d20a2ebacd02db380b27243b255/];
        is $args{method}, 'GET', 'HTTP GET method';
        is $args{content}, '', 'content';
        is $args{url}->as_string, 'https://graph.facebook.com/zuck', 'end point';

        return +{
            headers => [],
            status  => 304,
            message => 'Not Modified',
            content => +{},
        };

    };
};

subtest 'modified or invalid etag' => sub {
    send_request {

        my $fb   = Facebook::OpenGraph->new;
        my $user = $fb->fetch_with_etag('zuck', +{}, '539feb8aee5c3d20a2ebacd02db380b27243b255');

        ok $user, 'user returned';
        is $user->{id}, 4, 'user id';
        is $user->{name}, 'Mark Zuckerberg', 'user name';
        is $user->{first_name}, 'Mark', 'first name';
        is $user->{last_name}, 'Zuckerberg', 'last name';
        is $user->{link}, 'http://www.facebook.com/zuck', 'link';
        is $user->{username}, 'zuck', 'username';
        is $user->{gender}, 'male', 'gender';
        is $user->{locale}, 'en_US', 'locale';

    } receive_request {

        my %args = @_;
        is_deeply $args{headers}, [qw/IF-None-Match 539feb8aee5c3d20a2ebacd02db380b27243b255/];
        is $args{method}, 'GET', 'HTTP GET method';
        is $args{content}, '', 'content';
        is $args{url}->as_string, 'https://graph.facebook.com/zuck', 'end point';

        # Return values with status:200 when Open Graph object is modified
        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => +{
                id         => 4,
                name       => 'Mark Zuckerberg',
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

done_testing;
