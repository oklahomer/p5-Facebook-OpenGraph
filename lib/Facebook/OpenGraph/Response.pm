package Facebook::OpenGraph::Response;
use strict;
use warnings;
use Carp qw(croak);
use JSON::XS qw(decode_json);

sub new {
    my ($class, $args) = @_;
    croak('mandatory parameter "response" is not given')
        unless $args && $args->{response};

    return bless $args, $class;
}

sub response { shift->{response}        }
sub code     { shift->response->code    }
sub message  { shift->response->message }
sub content  { shift->response->content }

sub is_success {
    my $self = shift;
    # code 2XX or 304
    return $self->response->is_success || !$self->is_modified;
}

# Errors
# https://developers.facebook.com/docs/reference/api/errors/
sub error_string {
    my $self = shift;
    my $error = eval { decode_json($self->content)->{error}; };
    # sometimes error_subcode is not given
    return $@ ? $self->message
              : sprintf('%s:%s %s:%s', $error->{code}, $error->{error_subcode} || '-', $error->{type}, $error->{message});
}

sub as_json {
    my $self = shift;
    return $self->is_success ? $self->content # content is JSON formatted
                             : croak $self->error_string;
}

sub as_hashref {
    return decode_json(shift->as_json);
}

sub is_modified {
    my $self = shift;
    return $self->code != 304 || $self->message ne 'Not Modified';
}

1;
__END__
