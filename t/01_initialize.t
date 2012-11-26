use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;
use Furl;

subtest 'new' => sub {
    my $fb = Facebook::OpenGraph->new;
    isa_ok $fb, 'Facebook::OpenGraph', 'isa';
};

subtest 'accessor' => sub {
    my $fb = Facebook::OpenGraph->new(+{
        app_id       => '123456789',
        secret       => 'secretkey',
        access_token => '123456789|fooBarBuzz',
        namespace    => 'my_app_namespace', # mostly used to deal w/ open graph action
        ua           => Furl->new(agent => "Facebook::OpenGraph/$Facebook::OpenGraph::VERSION"),
    });

    is $fb->app_id, '123456789', 'app_id';
    is $fb->secret, 'secretkey', 'secret';
    is $fb->access_token, '123456789|fooBarBuzz', 'access_token';
    is $fb->namespace, 'my_app_namespace', 'namespace';
    my $ua = $fb->ua;
    isa_ok $ua, 'Furl', 'ua';
    is $ua->agent, "Facebook::OpenGraph/$Facebook::OpenGraph::VERSION", 'agent';
};

done_testing;
