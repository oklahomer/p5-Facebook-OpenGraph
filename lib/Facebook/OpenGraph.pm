package Facebook::OpenGraph;
use strict;
use warnings;
use Facebook::OpenGraph::Response;
use HTTP::Request::Common;
use URI;
use URI::QueryParam;
use Furl::HTTP;
use Data::Recursive::Encode;
use JSON::XS qw(encode_json decode_json);
use UNIVERSAL;
use Carp qw(croak);
use Digest::SHA qw(hmac_sha256);
use MIME::Base64::URLSafe qw(urlsafe_b64decode);

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $args  = shift || +{};
    return bless $args, $class;
}

sub app_id       { shift->{app_id}                 }
sub secret       { shift->{secret}                 }
sub ua           { shift->{ua} ||= Furl::HTTP->new }
sub namespace    { shift->{namespace}              }
sub access_token { shift->{access_token}           }
sub redirect_uri { shift->{redirect_uri}           }

sub uri {
    my ($self, $path) = @_;
    return URI->new_abs($path, 'https://graph.facebook.com/');
}

sub video_uri {
    my ($self, $path) = @_;
    return URI->new_abs($path, 'https://graph-video.facebook.com/');
}

# Using the signed_request Parameter: Step 1. Parse the signed_request
# https://developers.facebook.com/docs/howtos/login/signed-request/#step1
sub parse_signed_request {
    my ($self, $signed_request) = @_;
    croak 'signed_request is not given' unless $signed_request;
    croak 'secret key must be set' unless $self->secret;

    my ($enc_sig, $payload) = split(/\./, $signed_request);
    my $sig   = urlsafe_b64decode($enc_sig);
    my $datam = decode_json(urlsafe_b64decode($payload));

    croak 'algorithm must be HMAC-SHA256'
        unless uc($datam->{algorithm}) eq 'HMAC-SHA256';

    my $expected_sig = hmac_sha256($payload, $self->secret);
    croak 'Signature does not match' unless $sig eq $expected_sig;

    return $datam;
}

# OAuth Dialog: Constructing a URL to the OAuth Dialog
# https://developers.facebook.com/docs/reference/dialogs/oauth/
sub auth_uri {
    my ($self, $param_ref) = @_;
    $param_ref ||= +{};
    croak 'redirect_uri and app_id must be set'
        unless $self->redirect_uri && $self->app_id;

    if (my $scope_ref = ref $param_ref->{scope}) {
        $param_ref->{scope} =
            $scope_ref eq 'ARRAY' ? join ',', @{$param_ref->{scope}}
                                  : croak 'scope must be string or array ref';
    }
    $param_ref->{redirect_uri} = $self->redirect_uri;
    $param_ref->{client_id}    = $self->app_id;
    $param_ref->{display}      ||= 'page';
    my $uri = $self->uri('https://facebook.com/dialog/oauth/');
    $uri->query_form($param_ref);

    return $uri->as_string;
}

sub set_app_token {
    my ($self, $token) = @_;
    return $self->{access_token} = $token || $self->get_app_token;
}

# Login as an App: Step 1. Obtain an App Access Token
# https://developers.facebook.com/docs/howtos/login/login-as-app/#step1
sub get_app_token {
    my $self = shift;

    croak 'app_id and secret must be set' unless $self->app_id && $self->secret;
    my $token_ref = $self->_get_token(+{grant_type => 'client_credentials'});
    return $token_ref->{access_token};
}

sub get_user_token_by_code {
    my ($self, $code) = @_;

    croak 'code is not given' unless $code;
    croak 'redirect_uri must be set' unless $self->redirect_uri;

    my $query_ref = +{
        redirect_uri  => $self->redirect_uri,
        code          => $code,
    };
    my $token_ref = $self->_get_token($query_ref);
    croak 'expires is not returned' unless $token_ref->{expires};

    return $token_ref;
}

sub _get_token {
    my ($self, $param_ref) = @_;

    $param_ref = +{
        %$param_ref,
        client_id     => $self->app_id,
        client_secret => $self->secret,
    };

    my $response = $self->request('GET', '/oauth/access_token', $param_ref);
    # Get app_token from response content
    # content should be access_token=12345|QwerTy&expires=5183951 formatted
    my $res_content = $response->content;
    my $token_ref = +{URI->new('?'.$res_content)->query_form};
    croak 'can\'t get app_token properly: '.$res_content
        unless $token_ref->{access_token};

    return $token_ref;
}

sub fetch {
    return shift->request('GET', @_)->as_hashref;
}

# Using ETags
# https://developers.facebook.com/docs/reference/ads-api/etags-reference/
sub fetch_with_etag {
    my ($self, $uri, $param_ref, $etag) = @_;

    # Attach ETag value to header
    # Returns status 304 w/o contnet or status 200 w/ modified content
    my $response = $self->request('GET', $uri, $param_ref, ['IF-None-Match' => $etag]);

    return $response->is_modified ? $response->as_hashref
                                  : undef;
}

sub bulk_fetch {
    my ($self, $paths_ref) = @_;

    my @queries = map {
        +{method => 'GET', relative_url => $_}
    } @$paths_ref;

    return $self->batch(\@queries);
}

# Batch Requests
# https://developers.facebook.com/docs/reference/api/batch/
sub batch {
    my $self  = shift;
    my $batch = shift;

    my $responses_ref = $self->batch_fast($batch, @_);

    # Devide response content and create response objects that correspond to each request
    my @datam = ();
    for my $res_ref (@$responses_ref) {
        my @headers  = map { $_->{name} => $_->{value} } @{$res_ref->{headers}};
        my $response = $self->create_response(
            $res_ref->{code}, $res_ref->{message}, \@headers, $res_ref->{body},
        );
        croak $response->error_string unless $response->is_success;
        push @datam, $response->as_hashref;
    }

    return \@datam;
}

# doesn't create F::OG::Response object for each response
sub batch_fast {
    my $self  = shift;
    my $batch = shift;

    # Other than HTTP header, you need to set access_token as top level parameter.
    # You can specify individual token for each request
    # so you can act as several other users and/or pages.
    croak 'Top level access_token must be set' unless $self->access_token;
    my $query = +{
        access_token => $self->access_token || '',
        batch        => encode_json($batch),
    };

    return $self->request('POST', '', $query, @_)->as_hashref;
}

# Facebook Query Language (FQL)
# https://developers.facebook.com/docs/reference/fql/
sub fql {
    my $self  = shift;
    my $query = shift;
    return $self->fetch('/fql', +{q => $query}, @_);
}

# Facebook Query Language (FQL): Multi-query
# https://developers.facebook.com/docs/reference/fql/#multi
sub bulk_fql {
    my $self  = shift;
    my $batch = shift;

    my $param_ref = +{
        q => encode_json($batch),
    };
    return $self->request('GET', 'fql', $param_ref, @_)->as_hashref;
}

sub publish {
    return shift->request('POST', @_)->as_hashref;
}

# Graph API: Deleting
# https://developers.facebook.com/docs/reference/api/#deleting
sub delete {
    my ($self, $path) = @_;

    # Try DELETE method as described in document.
    my $response = $self->request('DELETE', $path);
    return $response->as_hashref if $response->is_success;

    # Sometimes sending DELETE method failes,
    # but POST method with method=delete works.
    # Weird...
    my $param_ref = +{
        method => 'delete',
    };
    return $self->request('POST', $path, $param_ref)->as_hashref;
}

sub request {
    my ($self, $method, $uri, $param_ref, $headers) = @_;

    $method    = uc $method;
    $uri       = $self->uri($uri) unless UNIVERSAL::isa($uri, 'URI');
    $param_ref = $self->prep_param(+{
        $uri->query_form,
        %{$param_ref || +{}},
    });
    $headers ||= [];
    push @$headers, (Authorization => sprintf('OAuth %s', $self->access_token))
        if $self->access_token;

    my $content = undef;
    if ($method eq 'POST') {
        $uri->query_form(+{});

        if ($param_ref->{source}) {
            # post photo or video to /OBJECT_ID/(photos|videos)

            # When posting a video, use graph-video.facebook.com .
            # For other actions, use graph.facebook.com/VIDEO_ID/CONNECTION_TYPE
            $uri->host($self->video_uri->host) if $uri->path =~ /\/videos$/;

            push @$headers, (Content_Type => 'form-data');
            my $req = POST $uri, @$headers, Content => [%$param_ref];
            $content = $req->content;
            my $req_header = $req->headers;
            $headers = +[
                map {
                    my $k = $_;
                    map { ( $k => $_ ) } $req_header->header($_);
                } $req_header->header_field_names
            ];
        }
        else {
            # post simple params such as message, link, description, etc...
            $content = $param_ref;
        }
    }
    else {
        $uri->query_form($param_ref);
        $content = '';
    }

    my ($res_minor_version, $res_status, $res_msg, $res_headers, $res_content)
        = $self->ua->request(
            method  => $method,
            url     => $uri,
            headers => $headers,
            content => $content,
        );

    my $response = $self->create_response(
        $res_status, $res_msg, $res_headers, $res_content
    );
    croak $response->error_string unless $response->is_success;

    return $response;
}

sub create_response {
    my ($self, $code, $message, $headers, $content) = @_;
    return Facebook::OpenGraph::Response->new(+{
        code    => $code,
        message => $message,
        headers => $headers,
        content => $content,
    });
}

sub prep_param {
    my ($self, $param_ref) = @_;

    $param_ref = Data::Recursive::Encode->encode_utf8($param_ref || +{});

    # Source parameter contains file path.
    # It must be an array ref to work w/ HTTP::Request::Common.
    if (my $path = $param_ref->{source}) {
        $param_ref->{source} = ref $path ? $path : [$path];
    }

    # use Field Expansion
    if (my $field_ref = $param_ref->{fields}) {
        $param_ref->{fields} = $self->prep_fields_recursive($field_ref);
    }

    return $param_ref;
}

# Field Expansion
# https://developers.facebook.com/docs/reference/api/field_expansion/
sub prep_fields_recursive {
    my ($self, $val) = @_;

    my $ref = ref $val;
    if (!$ref) {
        return $val;
    }
    elsif ($ref eq 'ARRAY') {
        return join ',', map { $self->prep_fields_recursive($_) } @$val;
    }
    elsif ($ref eq 'HASH') {
        my @strs = ();
        for my $k (keys %$val) {
            my $v = $val->{$k};
            my $r = ref $v;
            my $pattern = $r && $r eq 'HASH' ? '%s.%s' : '%s(%s)';
            push @strs, sprintf($pattern, $k, $self->prep_fields_recursive($v));
        }
        return join '.', @strs;
    }
}

# Updating Objects 
# https://developers.facebook.com/docs/technical-guides/opengraph/defining-an-object/#update
sub check_object {
    my ($self, $target) = @_;
    my $param_ref = +{
        id     => $target, # $target is object url or open graph object id
        scrape => 'true',
    };
    return $self->request('POST', '', $param_ref)->as_hashref;
}

1;
__END__

=head1 NAME

Facebook::OpenGraph -

=head1 SYNOPSIS

  use Facebook::OpenGraph;

=head1 DESCRIPTION

Facebook::OpenGraph is

=head1 AUTHOR

Oklahomer E<lt>hagiwara dot go at gmail dot comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
