use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;
use URI;
use t::Util;

subtest 'success' => sub {

    my $code    = 'XXXXXXXXXXXXXXXXXXXXXX';
    my $app_id  = 123456789;
    my $token   = '123456789XXXXXXXXXXX';
    my $expires = 5183814;

    send_request {

        # Redirect_uri should be exactly the same as the one
        # that you used on $fb->auth_uri
        my $fb = Facebook::OpenGraph->new(+{
            app_id       => $app_id,
            secret       => 'secret',
            redirect_uri => 'http://sample.com/auth_cb',
        });
        my $token_ref = $fb->get_user_token_by_code($code);
        is_deeply(
            $token_ref,
            +{
                access_token => $token,
                expires      => $expires,
            },
            'token',
        );

        is $fb->access_token, undef, 'access_token';
        $fb->set_access_token($token_ref->{access_token});        
        is $fb->access_token, $token, 'set_access_token';

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
                client_secret => 'secret',
                client_id     => $app_id,
                code          => $code,
                redirect_uri  => 'http://sample.com/auth_cb',
            },
            'query',
        );
        is $args{method}, 'GET', 'HTTP GET method';
        is $args{content}, '', 'content';

        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => sprintf('access_token=%s&expires=%d', $token, $expires),
        };

    };
};

done_testing;
