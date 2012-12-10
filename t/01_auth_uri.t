use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;

subtest '' => sub {
    my $fb = Facebook::OpenGraph->new(+{
        app_id => 1234567,
    });
    my $url = $fb->auth_uri(+{
        scope => [qw/email publish_actions/],
        redirect_uri => 'https://sample.com/auth_cb',
    });
    my $uri = URI->new($url);
    is $uri->scheme, 'https', 'scheme';
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

done_testing;
