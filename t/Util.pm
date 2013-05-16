package t::Util;
use base qw/Exporter/;

our @EXPORT = qw(
    send_request receive_request
); 

use JSON 2 qw(encode_json);
use Furl::HTTP;

sub send_request (&@) {
    my($code, $mock) = @_;
    no warnings 'redefine';
    local *Furl::HTTP::request = sub {
        shift;
        my $ret = $mock->(@_);

        my $content = '';
        my $headers = [];
        if (ref $ret->{content}) {
            # should be json formatted
            $content = encode_json($ret->{content});
            $headers = [
                'Content-Type' => 'application/json; charset=UTF-8',
            ];
        }
        else {
            # mostly for access_token
            $content = $ret->{content};
            $headers = [
                'Content-Type' => 'text/plain; charset=UTF-8',
            ];
        }
        push @$headers, 'Content-Length' => length($content);
        push @$headers, @{$ret->{headers}} if $ret->{headers};

        return (
            '0',
            $ret->{status},
            $ret->{message},
            $headers,
            $content,
        );
    };
    $code->();
}

sub receive_request (&) { shift }

1;
