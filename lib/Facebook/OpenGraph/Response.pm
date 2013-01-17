package Facebook::OpenGraph::Response;
use strict;
use warnings;
use Carp qw(croak);
use JSON::XS qw(decode_json);

sub new {
    my $class = shift;
    my $args  = shift || +{};

    return bless +{
        code    => $args->{code},
        message => $args->{message},
        content => $args->{content},
    }, $class;
}

# accessors
sub code    { shift->{code}    }
sub message { shift->{message} }
sub content { shift->{content} }

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
    # sometimes error_subcode is not given
    return $@ ? $self->message
              : sprintf('%s:%s %s:%s', $error->{code}, $error->{error_subcode} || '-', $error->{type}, $error->{message});
}

sub as_json {
    shift->content; # content is JSON formatted
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
