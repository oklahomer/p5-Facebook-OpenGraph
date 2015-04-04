use Modern::Perl;
use Facebook::OpenGraph;

# get access_token for application
my $token_ref = Facebook::OpenGraph->new(
    +{
        app_id => 75324055986753,
        secret => '291d7f26f909c137bba22cdf809c393',
    }
)->get_app_token;

use Data::Dumper;
say Dumper $token_ref;
say Dumper $token_ref->{access_token};

# user authorization
my $fb = Facebook::OpenGraph->new(
    +{
        app_id       => 35324055986753,
        secret       => '291d7f26f909c137bba22cdf809c393',
        namespace    => 'mishin_narod_ru',
        redirect_uri => 'https://sample.com/auth_callback',
    }
);
my $auth_url = $fb->auth_uri( +{ scope => [qw/email publish_actions/], } );
say Dumper $auth_url;
#my $req = Plack::Request->new($env);
#$token_ref = $fb->get_user_token_by_code( $req->query_param('code') );
#$fb->set_access_token( $token_ref->{access_token} );

#$c->redirect($auth_url);
#my $user_friendList = $fb->fetch('/me/friends');

#my   $user_friendList = $fb->fetch('/me/friends?access_token='.$token_ref->{access_token});
#say Dumper $user_friendList;

# my  	 $user_profile = $fb->fetch('/me','GET');
#say Dumper $user_profile;
