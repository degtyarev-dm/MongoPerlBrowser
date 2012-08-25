package mongoperlbrowser;
use Dancer ':syntax';
# use Dancer::Plugin::$mongo;
use MongoDB;
use Template;
use Data::Dumper;
use JSON::XS;

our $VERSION = '0.1';
my $flash;
my @dbs=();
my $json_encoder = JSON::XS->new->utf8()->allow_blessed->convert_blessed->pretty();
my $mongo = undef;
my $host = "";
my $dbName="";
my $collectionName="";

hook 'before' => sub {
    if (!$mongo && request->path_info !~ m{^/login}) 
    {
       var requested_path => request->path_info;
       request->path_info('/login');
    }

};

get '/' => sub {
    # if (!$mongo) { redirect "/login"; }
    template 'index';
};

any ['get', 'post'] => '/login' => sub {
   my $err;
   if ( request->method() eq "POST" ) 
   {
         if ( params->{'host'} ) 
         {
           $mongo = MongoDB::Connection->new(host => params->{'host'});
           $host = params->{'host'};
           redirect "/mongo";
         }
         else 
         {
           redirect "/";
         }
  }

  template 'login.tt', { 
    'err' => $err,
  };
};

get '/logout' => sub {
   session->destroy;
   set_flash('You are logged out.');
   redirect '/';
};

get '/mongo' => sub {
      @dbs = $mongo->database_names;
      template 'mongodb', { dbs => [@dbs] , host=>$host};
  };

get '/mongo/:dbs_name' => sub {
      my @resultCollections;
      $dbName = params->{'dbs_name'};
      my $database = $mongo->get_database(params->{'dbs_name'});
      my @collections = $database->collection_names;
      for(@collections)
      {
          push @resultCollections, $_ if( !/.*?\$.*/ );
      }
      
      template 'mongodb', { dbs => [@dbs], select=>params->{'dbs_name'}, collections=>[@resultCollections], dbName=>$dbName, host=>$host};
};

get '/mongo/:db_name/:collection_name' => sub {
      my ($dbs_name, $collection_name) = (params->{'db_name'}, params->{'collection_name'});
      $collectionName = $collection_name;
      my $collection = $mongo->get_database($dbs_name)->get_collection($collection_name);
      my @data = $collection->find({})->all;
      my @objects; 
      for(@data)
       {
          push @objects, $json_encoder->encode($_);
       }
      template 'mongodb.collection', { dbs => [@dbs], select=>$dbs_name, objects=>[@objects], dbName=>$dbName, collectionName=>$collectionName, host=>$host};
};

true;
