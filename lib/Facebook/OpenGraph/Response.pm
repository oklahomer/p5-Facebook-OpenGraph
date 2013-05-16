package Facebook::OpenGraph::Response;
use strict;
use warnings;
use Carp qw(croak);
use JSON 2 qw(decode_json);

sub new {
    my $class = shift;
    my $args  = shift || +{};

    return bless +{
        map {
            $_ => $args->{$_},
        } qw/code message content req_headers req_content/
    }, $class;
}

# accessors
sub code        { shift->{code}    }
sub message     { shift->{message} }
sub content     { shift->{content} }
sub req_headers { shift->{req_headers} || '' }
sub req_content { shift->{req_content} || '' }

sub is_success {
    my $self = shift;
    # code 2XX or 304
    return substr($self->code, 0, 1) == 2 || $self->code == 304;
}

# Errors
# https://developers.facebook.com/docs/reference/api/errors/
sub error_string {
    my $self = shift;
    my $error = eval { $self->as_hashref->{error}; };

    my $err_str = '';
    if ($@ || !$error) {
        $err_str = $self->message;
    }
    else {
        # sometimes error_subcode is not given
        $err_str = sprintf(
            '%s:%s %s:%s',
            $error->{code},
            $error->{error_subcode} || '-',
            $error->{type},
            $error->{message},
        );
    }

    return $err_str;
}

sub as_json {
    my $self = shift;
    if ((my $bool = $self->content) =~ m/^(true|false)$/) {
        # Sometimes they return plain text saying 'true' or 'false' to indicate
        # result. So make it JSON formatted for our convinience. The key is
        # named "success" so its format matches w/ some other endpoints that
        # return {"success": "(true|false)"}.
        $self->{content} = sprintf('{"success" : "%s"}', $bool);
    };
    return $self->content; # content is JSON formatted
}

sub as_hashref {
    # just in case content is not properly formatted
    my $hash_ref = eval { decode_json(shift->as_json); };
    croak $@ if $@;
    return $hash_ref;
}

sub is_modified {
    my $self = shift;
    my $not_modified = $self->code == 304  &&  $self->message eq 'Not Modified';
    return !$not_modified;
}

1;
__END__

=head1 NAME

Facebook::OpenGraph::Response - Response object for Facebook::OpenGraph.

=head1 SYNOPSIS

  my $res = Facebook::OpenGraph::Response->new(+{
      code        => $http_status_code,
      message     => $http_status_message,
      headers     => $response_headers,
      content     => $response_content,
      req_headers => $req_headers,
      req_content => $req_content,
  });

=head1 DESCRIPTION

This handles response object for Facebook::OpenGraph.

=head1 METHODS

=head2 Class Methods

=head3 C<< Facebook::OpenGraph::Response->new($status_code :Int, $status_mess :Str, $headers :ArrayRef, $content :Str) :Object >>

Creates and returns a new Facebook::OpenGraph::Response object.

=head2 Instance Methods

=head3 C<< $res->code() :Int >>

Returns HTTP status code

=head3 C<< $res->message() :Str >>

Returns HTTP status message

=head3 C<< $res->content() :Str >>

Returns response body

=head3 C<< $res->is_success() :Bool >>

Returns if status is 2XX or 304. 304 is added to handle $fb->fetch_with_etag();

=head3 C<< $res->error_string() :Str >>

Returns error string.

=head3 C<< $res->as_json() :Str >>

Returns response content as JSON string. Most of the time the response content 
itself is JSON formatted so it basically returns response content without doing 
anything. When Graph API returns plain text just saying 'true' or 'false,' it 
turns the content into JSON format like '{"success" : "(true|false)"}' so you 
can handle it in the same way as other cases.

=head3 C<< $res->as_hashref() :HashRef >>

Returns response content in hash reference.

=head3 C<< $res->is_modified() :Bool >>

Returns if target object is modified. This method is called in 
$fb->fetch_with_etag().
