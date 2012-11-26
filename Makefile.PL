use inc::Module::Install;
name 'Facebook-OpenGraph';
all_from 'lib/Facebook/OpenGraph.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
