use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use URI;
use t::Util;

subtest 'user' => sub {

    my $app_id = 127497087322461;
    my $datum_ref = +{
        display_name => 'app',
        icon_url => 'http://photos-c.ak.fbcdn.net/photos-ak-snc7/v43/45/'.$app_id.'/app_2_'.$app_id.'_1287.gif',
    };
    my $query = 'SELECT display_name, icon_url FROM application WHERE app_id = '.$app_id;

    send_request {
        
        my $fb = Facebook::OpenGraph->new;
        my $res = $fb->fql($query);

        is_deeply $res->{data}, [$datum_ref], 'data';

    } receive_request {

        my $url = URI->new;
        $url->query_form(+{q => $query});
        my %args = @_;
        is_deeply(
            \%args,
            +{
                headers => [],
                url     => 'https://graph.facebook.com/fql?'.$url->query,
                method  => 'GET',
                content => '',
            },
            'args'
        );

        return +{
            status  => 200,
            message => 'OK',
            content => +{
                data => [
                    $datum_ref,
                ],
            }
        };

    };
};

done_testing;
