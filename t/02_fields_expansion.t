use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use URI;
use t::Util;
use JSON 2 qw(encode_json);
eval "use YAML qw(LoadFile)";
plan skip_all => "YAML is not installed." if $@;

subtest 'field expansion' => sub {

    my $val = +{
        email   => 'foo_bar_buzz@tfbnw.net',
        name    => 'Linda Amdgjheicghf Laustein',
        id      => '12345678',
        albums  => +{
            data => [
                +{
                    created_time  => '2012-11-20T10:35:36+0000',
                    name          => 'test album',
                    id            => 111111111111111,
                    photos        => +{
                        data => [
                            +{
                                created_time => '2012-11-20T10:35:41+0000',
                                name         => 'abc',
                                id           => 123456,
                                picture      => 'http://photos-a.ak.fbcdn.net/hphotos-ak-ash4/123456_s.jpg',
                                tags         => +{
                                    paging => +{
                                        next => 'https://graph.facebook.com/12345678/tags?limit=2&offset=2',
                                    },
                                    data   => [
                                        +{
                                            y            => '50.42735042735',
                                            created_time => '2012-11-20T10:36:55+0000',
                                            name         => '100004657083353',
                                            x            => '74.137931034483'
                                        },
                                        +{
                                            y            => '33.333333333333',
                                            created_time => '2012-11-20T10:36:37+0000',
                                            name         => '100004691462769',
                                            x            => '47.931034482759'
                                        },
                                    ],
                                },
                            },
                            +{
                                created_time => '2012-11-20T10:35:41+0000',
                                name         => 'def',
                                id           => 23456,
                                picture      => 'http://photos-h.ak.fbcdn.net/hphotos-ak-prn1/23456_s.jpg',
                                tags         => +{
                                    paging => +{
                                        next => 'https://graph.facebook.com/12345678/tags?limit=2&offset=2'
                                    },
                                    data   => [
                                        +{
                                            y            => '37.142857142857',
                                            created_time => '2012-11-20T10:36:50+0000',
                                            name         => '100004657083353',
                                            x            => '44.137931034483'
                                        },
                                    ],
                                },
                            },
                            +{
                                created_time => '2012-11-20T10:35:41+0000',
                                id           => 34567,
                                picture      => 'http://photos-g.ak.fbcdn.net/hphotos-ak-ash3/34567_s.jpg'
                            },
                        ],
                    },
                },
            ],
        }
    };

    send_request {

        my $fb = Facebook::OpenGraph->new(+{
            access_token => 'qwerty',
        });
        my $fields = LoadFile('t/resource/fields.yaml');
        my $user   = $fb->fetch('me',  +{fields => $fields});

        is_deeply $user, $val, 'user';
    
    } receive_request {

        my %args   = @_;
        my %query  = URI->new(delete $args{url})->query_form;
        my $fields = $query{fields};

        my $user_field_match = $fields =~ s/(^name,email,albums)//;
        is $user_field_match, 1, 'user fields';

        my $albums_limit_match = $fields =~ s/(^\.limit\(5\)|\.limit\(5\)$)//;
        is $albums_limit_match, 1, 'albums limit';
        my $albums_fields_match = $fields =~ s/^\.fields\(name,photos(.*)\)$/$1/;
        is $albums_fields_match, 1, 'albums fields';

        my $photos_limit_match = $fields =~ s/(^\.limit\(3\)|\.limit\(3\)$)//;
        is $photos_limit_match, 1, 'photos limit';
        my $photos_fields_match = $fields =~ s/^\.fields\(name,picture,tags(.*)\)/$1/;
        is $photos_fields_match, 1, 'photos fields';

        my $tags_limit_match  = $fields =~ m/\.limit\(2\)/;
        is $tags_limit_match, 1, 'tags limit';

        is_deeply(
            \%args,
            +{
                headers => ['Authorization' => 'OAuth qwerty'],
                content => '',
                method  => 'GET',
            },
            'args'
        );

        return +{
            status  => 200,
            headers => [],
            message => 'OK',
            content => $val,
        };

    };
};

subtest 'w/ other params' => sub {

    send_request {

        my $fb     = Facebook::OpenGraph->new;
        my $fields = LoadFile('t/resource/fields.yaml');
        my $user   = $fb->fetch('/me', +{fields => $fields, locale => 'ja_JP'});

    } receive_request {

        my %args  = @_;
        my $uri   = $args{url};
        my %query = $uri->query_form;
        ok $query{locale}, 'locale';
        ok $query{fields}, 'fields';

        return +{
            status  => 200,
            headers => [],
            message => 'OK',
            content => encode_json({data => 'dummy'}),
        }

    };

};

done_testing;
