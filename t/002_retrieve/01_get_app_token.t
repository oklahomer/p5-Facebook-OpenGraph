use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;
use URI;
use t::Util;

subtest 'get' => sub {
    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            app_id => 123456789,
            secret => 'secret',
        });
        my $token = $fb->get_app_token->{access_token};
        is $token, '123456789|SSSeFWB-0EQ0qyipMdmNpJJJJjk', 'token';

    } receive_request {

        my %args = @_;
        is_deeply $args{headers}, [], 'no particular header';
        my $uri = $args{url};
        is $uri->scheme, 'https', 'scheme';
        is $uri->host, 'graph.facebook.com', 'host';
        is $uri->path, '/oauth/access_token', 'path';
        is_deeply(
            +{
                $uri->query_form,
            },
            +{
                grant_type    => 'client_credentials',
                client_secret => 'secret',
                client_id     => 123456789,
            },
            'query',
        );
        is $args{method}, 'GET', 'HTTP GET method';
        is $args{content}, '', 'content';

        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => 'access_token=123456789|SSSeFWB-0EQ0qyipMdmNpJJJJjk',
        };

    };
};

subtest 'w/o secret key' => sub {
        
    my $fb = Facebook::OpenGraph->new(+{
        app_id => 123456789,
    });

    throws_ok(
        sub {
            my $token = $fb->get_app_token->{access_token};
        },
        qr/app_id and secret must be set /,
        'secret key',
    );
    
};

subtest 'w/o secret key' => sub {
        
    my $fb = Facebook::OpenGraph->new(+{
        secret => 'secret',
    });

    throws_ok(
        sub {
            my $token = $fb->get_app_token->{access_token};
        },
        qr/app_id and secret must be set /,
        'secret key',
    );
    
};

done_testing;
