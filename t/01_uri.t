use strict;
use warnings;
use Test::More;
use Facebook::OpenGraph;

subtest 'beta' => sub {
    my $fb = Facebook::OpenGraph->new(+{
        is_beta => 1
    });

    subtest 'uri' => sub {
        my $uri = $fb->uri;
        is $uri->host, 'graph.beta.facebook.com', 'beta uri';
    };

    subtest 'uri w/ path' => sub {
        my $uri = $fb->uri('/foo');
        is $uri->path, '/foo', 'path';
    };

    subtest 'video_uri' => sub {
        my $uri = $fb->video_uri;
        is $uri->host, 'graph-video.beta.facebook.com', 'beta uri for video post';
    };
    
    subtest 'video_uri w/ path' => sub {
        my $uri = $fb->video_uri('/bar');
        is $uri->path, '/bar', 'path';
    };
};

subtest 'production' => sub {
    my $fb = Facebook::OpenGraph->new;
    subtest 'uri' => sub {
        my $uri = $fb->uri;
        is $uri->host, 'graph.facebook.com', 'production uri';
    };
    
    subtest 'uri w/ path' => sub {
        my $uri = $fb->uri('/foo');
        is $uri->path, '/foo', 'path';
    };

    subtest 'video_uri' => sub {
        my $uri = $fb->video_uri;
        is $uri->host, 'graph-video.facebook.com', 'production uri for video post';
    };
    
    subtest 'video_uri w/ path' => sub {
        my $uri = $fb->video_uri('/bar');
        is $uri->path, '/bar', 'path';
    };
};

done_testing;
