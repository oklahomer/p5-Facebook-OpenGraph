use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use t::Util;

subtest 'publish_action' => sub {

    my $datum_ref = +{
        id => 1234567890,
    };

    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            namespace    => 'foo-bar',
            access_token => 'AAAAAAAAAAA',
        });
        my $response = $fb->publish_action('give', +{crap => 'http://samples.ogp.me/428404590566358'});

        is_deeply $response, $datum_ref, 'response';

    } receive_request {

        my %args = @_;

        is_deeply(
            \%args,
            +{
                headers => [
                    'Authorization',
                    'OAuth AAAAAAAAAAA'
                ],
                url     => 'https://graph.facebook.com/me/foo-bar:give',
                method  => 'POST',
                content => +{
                    crap => 'http://samples.ogp.me/428404590566358',
                },
            },
            'args',
        );
        
        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => $datum_ref,
        };

    };

};

done_testing;
