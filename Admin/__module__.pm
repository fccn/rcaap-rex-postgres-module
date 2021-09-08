package Rex::Module::Database::Postgres::Admin;

use strict;
use warnings;

use Rex -base;
use Rex::Logger;
use Rex::Config;
use Rex::Module::Database::Postgres::Admin::Schema;
use Rex::Module::Database::Postgres::Admin::User;
use Data::Dumper;
use Rex::Commands::User;

my %PSQL_CONF = ();

#This comes from set => psql => user -> ... This psql ("psql" => sub ...) must be the same in set ....
Rex::Config->register_set_handler("psql" => sub {
   my ($name, $value) = @_;
   $PSQL_CONF{$name} = $value;
});

desc "Execute a query or a sql file with queries. Must be set => user => USERNAME in the task that calls this task";
task execute => sub {

   my $param = shift;
   die("You have to specify the sql to execute.") unless $param->{sql};

   my $sql = $param->{sql};   
   my ($tmp_file, $delete);

   if(is_file($sql)) {
      $tmp_file = $sql;
      $delete = 1 if $param->{deletefile};
   }
   else {
      $tmp_file = _tmp_file();
      $delete = 1;

      file $tmp_file, content => $sql;
   }

   Rex::Logger::debug("Executing: $sql");

   my $user      = $param->{user} || $PSQL_CONF{user};
   my $password  = $param->{password} || $PSQL_CONF{password};
   my $host      = $param->{host} || $PSQL_CONF{host} || 'localhost';
   my $db        = $param->{db} || $PSQL_CONF{db} || undef;
   
   my $db_stmt = '';
   $db_stmt = "-d $db" if defined($db);
   if ($db_stmt eq "") {
		$db_stmt = "template1";
   }
   
   Rex::Logger::info("Executing: psql -U $user -h $host $db_stmt");
   
   my $result;
   $result = run "psql -U $user -h $host $db_stmt < $tmp_file",
				env => {
					PGPASSWORD => "$password",
				};
   say $result unless $param->{quiet};   

   if($? != 0) {
      die("Error executing $sql");
   }
   
   unlink($tmp_file) if $delete;

   return $result;
};



sub get_variable {

   my $var = shift;

   return undef unless $var;

   my $variables = psqladmin( { command => 'variables' });

   return undef unless $variables; # error

   if ($variables =~ /^\| $var\s+\| (\w+)\s+\|/m) {

      return $1;
   }
   else {
      return '';
   }
};

sub _tmp_file {
   return "/tmp/" . rand(100) . ".sql";
}

1;

=pod

=head1 NAME

Rex::Module::Database::Postgres::Admin - Manage your Postgres Server

=head1 USAGE

 Use these parameters in yoy RexFile to set some user definitions:

 set psql => user => 'root';
 set psql => password => 'foobar';

IN COMMAND LINE OR as a argument calling the task:
 must pass the following arg in commad line --user=USER, --password=PASS, --dbname=DB, --host=HOST (these are required) and --template=TEMPLATE, --locale=LOCALE
 USER - The username to be created
 PASSWOR - The password for the user in the specific DB
 DBNAME - The database name
 HOST - The host that will executed the creation of user and database

 Template - example: template0
 locale - example: pt_PT.UTF8

 Module:Database:Postgres:Admin:setup --user=user --password=foobar --dbname=DBNAME --host=localhost

 Usage in task 
Database:Postgres:Admin:setup({
   user => USER,
   password => PASS,
   dbname => DB,
   host => host
})

=head1 USAGE

Use these parameters in yoy RexFile to set some user definitions:

 set psql => user => 'root';
 set psql => db => 'dname';

 Module:Database:Postgres:Admin:setup --sql="select * from A" if a sql command
 Module:Database:Postgres:Admin:setup --sql="PATH/database.sql" if a file with multiple sql commands
 or in a task
  Module:Database:Postgres:Admin:setup({sql => 'select * from A'})
  Module:Database:Postgres:Admin:setup({sql => 'PATH/database.sql'})

  where path is the path of the sql file



