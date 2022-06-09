package Rex::Module::Database::Postgres::Admin::Database;
   
use strict;
use warnings;

use Rex -base;
use Rex::Module::Database::Postgres::Admin;

task create => sub {

   my $param = shift;
   die("You have to specify the database name.") unless $param->{name};

   my $db = $param->{name};
   my $host = $param->{host} || "localhost";
   my $encoding = $param->{encoding} || "UTF8";
   my $template = $param->{template} || "template0";
      
   Rex::Module::Database::Postgres::Admin::execute({sql => "CREATE DATABASE IF NOT EXISTS $db ENCODING '$encoding' TEMPLATE $template;\n"});

};


desc "drops Database";
task drop => sub {

   my $param = shift;
   die("You have to specify the database name.") unless $param->{name};

   my $user = $param->{user} || "postgres";
   my $db = $param->{name};

   
   Rex::Module::Database::Postgres::Admin::execute({sql => "DROP DATABASE IF EXISTS $db;\n"});

   #CHANGE TO CREATEDB -- TODO
   #my $result = run "dropdb -U $user $db";

};


1;

=pod

=head1 NAME

Rex::Module::Database::Postgres::Admin::Schema - Manage a Schema

=head1 USAGE

 task "taskname", sub {
    Rex::Module::Database::Postgres::Admin::Schema::create({
       name => "foo",
    });
 };

=head1 MODULE FUNCTIONS

=over 4

=item create({name => $schema_name})

Create a new Database Schema.

 Rex::Module::Database::Postgres::Admin::Schema::create({
    name => "foobar",
 });

=item drop({name => $schema_name, cascade => 1})

Drop a Database Schema.

 Rex::Module::Database::Postgres::Admin::Schema::drop({
    name => "foobar",
    cascade => 1
 });

The cascade parameter is only used if all objects need to be deleted or the schema is not empty

=back

=cut

