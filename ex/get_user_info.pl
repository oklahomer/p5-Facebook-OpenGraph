use Modern::Perl;
use Facebook::OpenGraph;

# fetching public information about given objects
my $fb   = Facebook::OpenGraph->new;
my $user = $fb->fetch('mishin');

use Data::Dumper;
say Dumper $user;
