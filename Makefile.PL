use inc::Module::Install;
name 'Facebook-OpenGraph';
all_from 'lib/Facebook/OpenGraph.pm';

requires 'URI';
requires 'HTTP::Message';
requires 'Data::Recursive::Encode';
requires 'Furl';
requires 'JSON';
requires 'MIME::Base64::URLSafe';

tests 't/*.t t/*/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::Mock::Furl';
auto_set_repository;
auto_include;
WriteAll;
