package Facebook::OpenGraph::Response;
use strict;
use warnings;
use Carp qw(croak);
use JSON::XS qw(decode_json);

sub new {
    my ($class, $args) = @_;

    return bless $args, $class;
}

sub code     { shift->{code}    }
sub message  { shift->{message} }
sub content  { shift->{content} }

sub is_success {
    my $self = shift;
    # code 2XX or 304
    return substr($self->code, 0, 1) eq '2' || $self->code == 304;
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
    return decode_json(shift->as_json);
}

sub is_modified {
    my $self = shift;
    return $self->code != 304 || $self->message ne 'Not Modified';
}

1;
__END__
