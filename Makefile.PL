use inc::Module::Install;
name 'Facebook-OpenGraph';
all_from 'lib/Facebook/OpenGraph.pm';

requires 'Data::Recursive::Encode';
requires 'Digest::SHA';
requires 'Furl';
requires 'Furl::HTTP';
requires 'HTTP::Request::Common';
requires 'JSON', '2';
requires 'MIME::Base64::URLSafe';
requires 'Module::Build';
requires 'Parse::CPAN::Meta';
requires 'Scalar::Util';
requires 'Sub::Uplevel';
requires 'URI';
requires 'HTTP::Message';
requires 'parent';
requires 'perl', '5.006';

tests 't/*.t t/*/*.t';
author_tests 'xt';

test_requires 'Test::Builder';
test_requires 'Test::Builder::Module';
test_requires 'Test::Builder::IO::Scalar';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::MockObject';
test_requires 'Test::Mock::Furl';
auto_set_repository;
auto_include;
WriteAll;
