use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;

subtest 'correct' => sub {

    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 1234567,
        redirect_uri => 'https://sample.com/auth_cb',
    });
    my $url = $fb->auth_uri(+{
        scope => [qw/email publish_actions/],
    });

    my $uri = URI->new($url);
    is $uri->scheme, 'https', 'scheme';
    is $uri->host, 'facebook.com', 'host';
    is $uri->path, '/dialog/oauth/', 'path';
    is_deeply(
        +{$uri->query_form},
        +{
            redirect_uri =>'https://sample.com/auth_cb',
            scope        => 'email,publish_actions',
            display      => 'page',
            client_id    => 1234567,
        },
        'query parameter',
    );

};

subtest 'w/o scope' => sub {

    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 1234567,
        redirect_uri => 'https://sample.com/auth_cb',
    });
    my $url = $fb->auth_uri;

    ok $url, 'scope is optional';

};

subtest 'w/o redirect_uri' => sub {

    my $fb = Facebook::OpenGraph->new(+{
        app_id => 1234567,
    });

    throws_ok(
        sub {
            my $url = $fb->auth_uri(+{
                scope => [qw/email publish_actions/],
            });
        },
        qr/redirect_uri and app_id must be set/,
        'scopre value is hashref'
    );

};

subtest 'wrong scopre value' => sub {

    my $fb = Facebook::OpenGraph->new(+{
        app_id       => 1234567,
        redirect_uri => 'https://sample.com/auth_cb',
    });

    throws_ok(
        sub {
            my $url = $fb->auth_uri(+{
                scope => +{ publish_actions => 1, email => 0 },
            });
        },
        qr/scope must be string or array ref/,
        'scopre value is hashref'
    );

};

done_testing;
