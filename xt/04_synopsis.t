use Test::More;
eval "use Test::Synopsis; use ExtUtils::Manifest";
plan skip_all => "Test::Synopsis, ExtUtils::Manifest required for testing" if $@;
plan skip_all => "There is no MANIFEST file" unless -f 'MANIFEST';
all_synopsis_ok();
