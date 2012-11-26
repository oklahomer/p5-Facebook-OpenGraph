package Facebook::OpenGraph;
use strict;
use warnings;
use Facebook::OpenGraph::Response;
use URI;
use URI::QueryParam;
use Furl;
use Furl::Response;
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

sub app_id       { shift->{app_id}           }
sub secret       { shift->{secret}           }
sub ua           { shift->{ua} ||= Furl->new }
sub namespace    { shift->{namespace}        }
sub access_token { shift->{access_token}     }

sub uri {
    my ($self, $path) = @_;
    return URI->new_abs($path, 'https://graph.facebook.com/');
}

sub video_uri {
    my ($self, $path) = @_;
    return URI->new_abs($path, 'https://graph-video.facebook.com/');
}

sub parse_signed_request {
    my ($self, $signed_request) = @_;
    croak 'signed_request is not given' unless $signed_request;
    croak 'secret key must be set' unless $self->secret;

    my ($enc_sig, $payload) = split(/\./, $signed_request);
    my $sig   = urlsafe_b64decode($enc_sig);
    my $datam = decode_json(urlsafe_b64decode($payload));

    croak 'algorithm must be HMAC-SHA256' unless uc($datam->{algorithm}) eq 'HMAC-SHA256';

    my $expected_sig = hmac_sha256($payload, $self->secret);
    croak 'Signature does not match' unless $sig eq $expected_sig;

    return $datam;
}

# https://developers.facebook.com/docs/reference/dialogs/oauth/
sub auth_uri {
    my ($self, $params_ref) = @_;
    $params_ref ||= +{};
    croak 'redirect_uri is not given' unless $params_ref->{redirect_uri};

    if (my $scope_ref = ref $params_ref->{scope}) {
        $params_ref->{scope} =
            $scope_ref eq 'ARRAY' ? join ',', @{$params_ref->{scope}}
                                  : croak 'scope must be string or array ref';
    }
    $params_ref->{client_id} ||= $self->app_id;
    $params_ref->{display}   ||= 'page';
    my $uri = $self->uri('/oauth/dialog');
    $uri->query_form($params_ref);

    return $uri->as_string;
}

sub set_app_token {
    my ($self, $token) = @_;
    return $self->{access_token} = $token || $self->get_app_token;
}

# Page: Page Access Tokens
# https://developers.facebook.com/docs/reference/api/page/#page_access_tokens
sub get_app_token {
    my $self = shift;

    croak 'app_id and secret must be set'
        unless $self->app_id && $self->secret;

    my $query_ref = +{
        client_id     => $self->app_id,
        client_secret => $self->secret,
        grant_type    => 'client_credentials',
    };
    my $response = $self->request('GET', '/oauth/access_token', $query_ref);

    return URI->new('?'.$response->content)->query_param('access_token');
}

sub fetch {
    return shift->request('GET', @_)->as_hashref;
}

# Using ETags
# https://developers.facebook.com/docs/reference/ads-api/etags-reference/
# $fb->fetch('me', +{fields => [qw(f1 f2)]}, ETAG_VALUE);
sub fetch_with_etag {
    my ($self, $uri, $datam, $etag) = @_;

    my $response = $self->request('GET', $uri, $datam, ['IF-None-Match' => $etag]);

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
    my ($self, $batch) = @_;

    my $batch_response = $self->batch_fast($batch);

    # Devide response content and create response objects that correspond to each request
    my @datam = ();
    for my $content (@{$batch_response->as_hashref}) {
        my @headers  = map { $_->{name} => $_->{value} } @{$content->{headers}};
        my $response = Furl::Response->new(
            $batch_response->response->{minor_version},
            $content->{code},
            $content->{message},
            \@headers,
            $content->{body},
        );

        my $res_obj = Facebook::OpenGraph::Response->new(+{
            response => $response,
        });
        croak $res_obj->error_string unless $res_obj->is_success;
        push @datam, $res_obj->as_hashref;
    }

    return \@datam;
}

# doesn't create F::OG::Response object for each response
sub batch_fast {
    my ($self, $batch) = @_;

    # Other than HTTP header, you need to set access_token as top level parameter.
    # You can specify individual token for each request
    # so you can act as several other users and/or pages.
    croak 'Top level access_token must be set' unless $self->access_token;
    my $query = +{
        access_token => $self->access_token || '',
        batch        => encode_json($batch),
    };

    return $self->request('POST', '', $query, []);
}

# # Facebook Query Language (FQL)
# https://developers.facebook.com/docs/reference/fql/
sub fql {
    my ($self, $query) = @_;
    return $self->request('GET', 'fql', +{q => $query}, [])->as_hashref;
}

# Facebook Query Language (FQL): Multi-query
# https://developers.facebook.com/docs/reference/fql/#multi
sub bulk_fql {
    my ($self, $batch) = @_;
    my $param_ref = +{
        q => encode_json($batch),
    };
    return $self->request('GET', 'fql', $param_ref)->as_hashref;
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
    my $params_ref = +{
        method => 'delete',
    };
    return $self->request('POST', $path, $params_ref)->as_hashref;
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
        # When posting a video, use graph-video.facebook.com .
        # For other actions, use graph.facebook.com/VIDEO_ID/CONNECTION_TYPE
        $uri->host($self->video_uri->host) if $uri->path =~ /\/videos$/;
        $uri->query_form(+{});
        $content = $param_ref;
    }
    else {
        $uri->query_form($param_ref);
        $content = '';
    }

    my $response = $self->ua->request(
        method  => $method,
        url     => $uri,
        headers => $headers,
        content => $content,
    );
    my $res_obj = Facebook::OpenGraph::Response->new(+{
        response => $response,
    });
    croak $res_obj->error_string unless $res_obj->is_success;

    return $res_obj;
}

sub prep_param {
    my ($self, $param_ref) = @_;

    $param_ref = Data::Recursive::Encode->encode_utf8($param_ref || +{});
    $param_ref->{fields} = $self->prep_fields_recursive($param_ref->{fields})
        if $param_ref->{fields};

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
