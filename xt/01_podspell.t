use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Oklahomer
Facebook::OpenGraph
API
fql
gmail
namespace
ua
url
Facebook's
OAuth
ETag
customizability
uri
JSON
API's
refetch
multi
OGP
