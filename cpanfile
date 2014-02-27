requires 'Data::Recursive::Encode';
requires 'Digest::SHA';
requires 'Furl';
requires 'Furl::HTTP';
requires 'HTTP::Message';
requires 'HTTP::Request::Common';
requires 'JSON', '2';
requires 'MIME::Base64::URLSafe';
requires 'Module::Build';
requires 'Parse::CPAN::Meta';
requires 'Scalar::Util';
requires 'Sub::Uplevel';
requires 'URI';
requires 'parent';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::Exception';
    requires 'Test::Mock::Furl';
    requires 'Test::MockObject';
};
