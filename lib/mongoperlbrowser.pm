package mongoperlbrowser;
use Dancer ':syntax';
use Dancer::Plugin::Mongo;
use Template;
use Data::Dumper;
use JSON::XS;

our $VERSION = '0.1';
my $flash;
my @dbs=();
my $json_encoder = JSON::XS->new->utf8()->allow_blessed->convert_blessed->pretty();

get '/' => sub {
  	if ( not session('logged_in') ) {
		# send_error("Not logged in", 401);
		redirect "/login";
	}
    template 'index';
};

sub set_flash {
	my $message = shift;

	$flash = $message;
}

sub get_flash {

	my $msg = $flash;
	$flash = "";

	return $msg;
}

any ['get', 'post'] => '/login' => sub {
   my $err;
   redirect "/" if(session('logged_in'));
   if ( request->method() eq "POST" ) 
   {
         if ( params->{'username'} ne setting('username') ) 
        {
           $err = "Invalid username";
         }
         elsif ( params->{'password'} ne setting('password') ) 
         {
           $err = "Invalid password";
         }
         else 
         {
           session 'logged_in' => true;
           set_flash('You are logged in.');
           redirect "/";
         }
  }

  # display login form
  template 'login.tt', { 
    'err' => $err,
  };
};

get '/logout' => sub {
   session->destroy;
   set_flash('You are logged out.');
   redirect '/';
};

before_template sub {
	my $tokens = shift;

	$tokens->{'login_url'} = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');
};

get '/mongo' => sub {
    #if login
  
   @dbs = mongo->database_names;

    template 'mongodb', { dbs => [@dbs]};
};

get '/mongo/:dbs_name' => sub {
    #if login
    my @resultCollections;
    my $database = mongo->get_database(params->{'dbs_name'});
    my @collections = $database->collection_names;
    for(@collections)
    {
        push @resultCollections, $_ if( !/.*?\$.*/ );
    }
    
    template 'mongodb', { dbs => [@dbs], select=>params->{'dbs_name'}, collections=>[@resultCollections]};
};

get '/mongo/:db_name/:collection_name' => sub {
    #if login
    my ($dbs_name, $collection_name) = (params->{'db_name'}, params->{'collection_name'});
    my $collection = mongo->get_database($dbs_name)->get_collection($collection_name);
    my @data = $collection->find({})->all;
    my @objects; 
    for(@data)
     {
        push @objects, $json_encoder->encode($_);
     }
    template 'mongodb.collection', { dbs => [@dbs], select=>$dbs_name, objects=>[@objects]};
};

true;
