use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use URI;
use t::Util;

subtest 'user' => sub {
    send_request {
        
        my $fb = Facebook::OpenGraph->new;
        my $res = $fb->fql(
            'SELECT display_name, icon_url FROM application WHERE app_id = 127497087322461'
        );

        ok $res->{data};
        my $data = $res->{data}[0];
        is $data->{display_name}, 'app', 'display name';
        is $data->{icon_url}, 'http://photos-c.ak.fbcdn.net/photos-ak-snc7/v43/45/127497087322461/app_2_127497087322461_1287.gif', 'icon url';

    } receive_request {

        my %args = @_;
        is_deeply $args{headers}, [], 'no particular header';
        my $uri = $args{url};
        is $uri->scheme, 'https', 'scheme';
        is $uri->host, 'graph.facebook.com', 'host';
        is_deeply(
            +{ $uri->query_form },
            +{
                'q' => 'SELECT display_name, icon_url FROM application WHERE app_id = 127497087322461',
            },
            'end point',
        );
        is $args{method}, 'GET', 'HTTP GET method';
        is $args{content}, '', 'content';

        return +{
            status  => 200,
            message => 'OK',
            content => +{
                data => [
                    +{
                        display_name => 'app',
                        icon_url => 'http://photos-c.ak.fbcdn.net/photos-ak-snc7/v43/45/127497087322461/app_2_127497087322461_1287.gif',
                    }
                ],
            }
        };

    };
};

done_testing;
