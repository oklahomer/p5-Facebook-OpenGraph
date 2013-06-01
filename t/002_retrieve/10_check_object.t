use strict;
use warnings;
use Test::More;
use Test::Exception;
use Facebook::OpenGraph;
use t::Util;
use JSON 2 qw(encode_json);

# samples URLs are found at https://developers.facebook.com/tools/debug/examples/
subtest 'good'  => sub {

    my $target = 'https://developers.facebook.com/tools/debug/examples/good';

    my $val = +{
        application => +{
            url  => 'http://www.facebook.com/apps/application.php?id=115109575169727',
            name => 'IMDb',
            id   => 115109575169727,
        },
        description => "Directed by Michael Bay. With Sean Connery, Nicolas Cage, Ed Harris, John Spencer. A renegade general and his group of U.S. Marines take over Alcatraz and threaten San Francisco Bay with biological weapons. A chemical weapons specialist and the only man to have ever escaped from the Rock attempt to \x{2026}",
        image => [
            +{
                url => 'http://ia.media-imdb.com/images/M/MV5BMTM3MTczOTM1OF5BMl5BanBnXkFtZTYwMjc1NDA5._V1._SX98_SY140_.jpg',
            }
        ],
        updated_time => '2012-11-24T01:28:22+0000',
        url          => 'http://www.imdb.com/title/tt0117500/',
        type         => 'video.movie',
        title        => 'The Rock (1996)',
        id           => '380728101301',
        site_name    => 'IMDb',
    };

    send_request {

        my $fb = Facebook::OpenGraph->new;
        my $response   = $fb->check_object($target);

        is_deeply $response, $val, 'response';

    } receive_request {
    
        my %args = @_;
        is_deeply(
            \%args,
            +{
                headers => [],
                method  => 'POST',
                url     => 'https://graph.facebook.com/',
                content => +{
                    id     => $target,
                    scrape => 'true',
                },
            },
            'args',
        );

        return +{
            message => 'OK',
            status  => 200,
            headers => [],
            content => $val,
        };
    
    };
};

subtest 'bad app id' => sub {
        
    my $target = 'https://developers.facebook.com/tools/debug/examples/bad_app_id';

    my $error_code    = 1611016;
    my $error_type    = 'Exception';
    my $error_message = "Object at URL 'https://developers.facebook.com/tools/debug/examples/bad_app_id' of type 'website' is invalid because the given value 'Paul is Awesome' for property 'fb:app_id' could not be parsed as type 'fbid'.";

    send_request {

        my $fb = Facebook::OpenGraph->new;
        throws_ok sub { $fb->check_object($target) }, qr/$error_code:- $error_type:$error_message/, 'exception';

    } receive_request {

        my %args = @_;
        is_deeply(
            \%args,
            +{
                method  => 'POST',
                headers => [],
                url     => 'https://graph.facebook.com/',
                content => +{
                    id     => $target,
                    scrape => 'true',
                },
            },
            'args'
        );
        
        return +{
            status  => 500,
            headers => [],
            message => 'Internal Server Error',
            content => encode_json(+{
                error => +{
                    type    => $error_type,
                    message => $error_message,
                    code    => $error_code,
                },
            }),
        };

    };
};

subtest 'bad domain' => sub {

    my $target = 'https://developers.facebook.com/tools/debug/examples/bad_domain';

    my $val = +{
        id           => 10150096126766188,
        url          => "http://www.iana.org/domains/example/",
        type         => "website",
        title        => "IANA - Example domains",
        description  => "As described in RFC 2606, we maintain a number of domains such as EXAMPLE.COM and EXAMPLE.ORG for documentation purposes. These domains may be used as illustrative examples in documents without prior coordination with us. They are not available for registration.",
        updated_time => "2012-11-24T14:19:29+0000",
        image => [
            +{
                url => "http://www.iana.org/_img/iana-logo-pageheader.png",
            }
        ],
    };

    send_request {

        my $fb = Facebook::OpenGraph->new;
        my $response = $fb->check_object($target);

        is_deeply $response, $val, 'response';

    } receive_request {

        my %args = @_;
        
        is_deeply(
            \%args,
            +{
                headers => [],
                method  => 'POST',
                url     => 'https://graph.facebook.com/',
                content => +{
                    id     => $target,
                    scrape => 'true',
                },
            },
            'args'
        );

        return +{
            status  => 200, # Isn't it weird that they give 500 for bad app_id and now give us 200?
            message => 'OK',
            headers => [],
            content => $val,
        };

    };
};

subtest 'bad type' => sub {

    my $target = 'https://developers.facebook.com/tools/debug/examples/bad_type';

    my $error_code    = 1611007;
    my $error_type    = 'Exception';
    my $error_message = "Object at URL 'https://developers.facebook.com/tools/debug/examples/bad_type' is invalid because the configured 'og:type' of 'paul isn't a type' is invalid.";

    send_request {

        my $fb = Facebook::OpenGraph->new;
        throws_ok sub { $fb->check_object($target) }, qr/$error_code:- $error_type:$error_message/, 'exception';

    } receive_request {

        my %args = @_;
        is_deeply(
            \%args,
            +{
                headers => [],
                method  => 'POST',
                url     => 'https://graph.facebook.com/',
                content => +{
                    id     => $target,
                    scrape => 'true',
                },
            },
            'args'
        );

        return +{
            content => encode_json(+{
                error => +{
                    code    => $error_code,
                    type    => $error_type,
                    message => $error_message,
                },
            }),
            message => 'Internal Server Error',
            status  => 500,
            headers => [],
        };

    };

};

subtest 'missing property' => sub {
        
    my $target = 'https://developers.facebook.com/tools/debug/examples/missing_property';

    my $val = +{
        url   => 'https://developers.facebook.com/tools/debug/examples/missing_property',
        type  => 'book',
        title => 'https://developers.facebook.com/tools/debug/examples/missing_property',
        id    => 10150426817266040,
        updated_time => '2012-11-24T15:47:23+000',
    };

    send_request {

        my $fb = Facebook::OpenGraph->new;
        my $response = $fb->check_object($target);

        is_deeply $response, $val, 'result';

    } receive_request {

        my %args = @_;
        is_deeply(
            \%args,
            +{
                headers => [],
                method  => 'POST',
                url     => 'https://graph.facebook.com/',
                content => +{
                    id     => $target,
                    scrape => 'true',
                },
            },
            'args'
        );

        return +{
            status  => 200,
            message => 'OK',
            content => $val,
            headers => [],
        };

    };

};

subtest 'invalid property' => sub {
        
    my $target = 'https://developers.facebook.com/tools/debug/examples/invalid_property';

    my $val = +{
        updated_time => '2012-11-24T15:54:27+0000',
        url          => 'htps://developers.facebook.com/tools/debug/examples/invalid_property',
        id           => 10150748655040220,
        data         => +{
            isbn => 'Paul isn\'t an ISBN',
        },
        title => 'Ender\'s Game',
        type  => 'book',
        image => [
            +{
                url => 'http://upload.wikimedia.org/wikipedia/en/e/e4/Ender%27s_game_cover_ISBN_0312932081.jpg',
            }
        ],
    };

    send_request {

        my $fb = Facebook::OpenGraph->new;
        my $response = eval { $fb->check_object($target); };

        is_deeply $response, $val, 'response';

    } receive_request {

        my %args = @_;
        is_deeply(
            \%args,
            +{
                headers => [],
                method  => 'POST',
                url     => 'https://graph.facebook.com/',
                content => +{
                    id     => $target,
                    scrape => 'true',
                },
            },
            'args'
        );

        return +{
            status  => 200,
            message => 'OK',
            content => $val,
            headers => [],
        };

    };


};

done_testing;
