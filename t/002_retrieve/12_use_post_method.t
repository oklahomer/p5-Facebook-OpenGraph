use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;
use t::Util;
use URI;

subtest 'w/o use_post_method setting' => sub {

    send_request {

        my $fb = Facebook::OpenGraph->new;
        $fb->get('go.hagiwara');

    } receive_request {

        my %args = @_;
        is $args{method}, 'GET', 'HTTP method';
        is $args{content}, '', 'content';

        return +{
            headers => [], 
            status  => 200,
            message => 'OK',
            content => +{
                dummy => 'data',
            }
        };

    };

};

subtest 'use_post_method setting w/ GET' => sub {

    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            access_token    => 'qwerty',
            use_post_method => 1,
        });
        $fb->get('/me');

    } receive_request {

        my %args = @_;
        is_deeply(
            \%args,
            +{
                method => 'POST',
                url    => 'https://graph.facebook.com/me',
                headers => [
                    Authorization => 'OAuth qwerty',
                ],
                content => +{
                    method => 'GET',
                },
            },
        );

        return +{
            headers => [], 
            status  => 200,
            message => 'OK',
            content => +{
                dummy => 'data',
            }
        };

    };

};

subtest 'use_post_method setting w/ DELETE' => sub {

    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            access_token    => 'qwerty',
            use_post_method => 1,
        });
        $fb->delete(123456);

    } receive_request {

        my %args = @_;
        is_deeply(
            \%args,
            +{
                method => 'POST',
                url    => 'https://graph.facebook.com/123456',
                headers => [
                    Authorization => 'OAuth qwerty',
                ],
                content => +{
                    method => 'DELETE',
                },
            },
        );

        return +{
            headers => [], 
            status  => 200,
            message => 'OK',
            content => +{
                dummy => 'data',
            }
        };

    };

};

done_testing;
