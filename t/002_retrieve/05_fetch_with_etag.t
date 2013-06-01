use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use t::Util;

subtest 'etag' => sub {

    my $etag = '539feb8aee5c3d20a2ebacd02db380b27243b255';

    send_request {

        my $fb = Facebook::OpenGraph->new;
        my $user = $fb->fetch_with_etag('zuck', +{}, $etag);

        is $user, undef, 'not modified';

    } receive_request {

        my %args = @_;

        is_deeply(
            \%args,
            +{
                headers => ['IF-None-Match' => $etag],
                method  => 'GET',
                content => '',
                url     => 'https://graph.facebook.com/zuck',
            },
            'args'
        );

        # Returns status:304 w/ empty content when object is not modified
        return +{
            headers => [],
            status  => 304,
            message => 'Not Modified',
            content => +{},
        };

    };
};

subtest 'modified or invalid etag' => sub {

    my $datum_ref = +{
        id         => 4,
        name       => 'Mark Zuckerberg',
        locale     => 'en_US',
        last_name  => 'Zuckerberg',
        username   => 'zuck',
        first_name => 'Mark',
        gender     => 'male',
        link       => 'http://www.facebook.com/zuck',
    };
    my $etag = '539feb8aee5c3d20a2ebacd02db380b27243b255';

    send_request {

        my $fb   = Facebook::OpenGraph->new;
        my $user = $fb->fetch_with_etag('zuck', +{}, $etag);

        is_deeply $user, $datum_ref, 'datum';

    } receive_request {

        my %args = @_;

        is_deeply(
            \%args,
            +{
                headers => ['IF-None-Match' => $etag],
                method  => 'GET',
                content => '',
                url     => 'https://graph.facebook.com/zuck',
            },
            'args'
        );

        # Return values with status:200 when Open Graph object is modified
        return +{
            headers => [],
            status  => 200,
            message => 'OK',
            content => $datum_ref,
        };

    };
};

done_testing;
