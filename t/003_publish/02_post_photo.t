use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use t::Util;

subtest 'post photo' => sub {
    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            app_id       => 12345678,
            access_token => '12345qwerty',
        });
        my $response = $fb->publish('/me/photos',+{ source => './t/resource/sample.png', message => 'upload photo'});
        is $response->{id}, 100550186784540, 'id';
        is $response->{post_id}, 100004886761157_100537230119169, 'post_id';

    } receive_request {

        my %args = @_;
        ok delete $args{content}, 'content'; # too huge to compare, so just check if it's given
        is_deeply(
            \%args,
            +{
                method  => 'POST',
                url     => 'https://graph.facebook.com/me/photos',
                headers => [
                    'Authorization'  => 'OAuth 12345qwerty',
                    'Content-Length' =>  69332,
                    'Content-Type'   => 'multipart/form-data; boundary=xYzZY',
                ],
            }
        );

        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => +{
                post_id => 100004886761157_100537230119169, # user_id + post id combo
                id      => 100550186784540,
            }
        }

    }
};


done_testing;
