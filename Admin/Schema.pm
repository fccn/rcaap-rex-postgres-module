package Rex::Module::Database::Postgres::Admin::Schema;
   
use strict;
use warnings;

use Rex -base;
use Rex::Module::Database::Postgres::Admin;


task create => sub {

   my $param = shift;
   die("You have to specify the schema name.") unless $param->{name};

   my $schema = $param->{name};

   Rex::Module::Database::Postgres::Admin::execute({sql => "CREATE SCHEMA $schema;\n"});

};

task drop => sub {

   my $param = shift;
   die("You have to specify the schema name.") unless $param->{name};

   my $drop_cascade = exists $param->{cascade} ? "CASCADE" : "";
   my $schema = $param->{name};

   Rex::Module::Database::Postgres::Admin::execute({sql => "DROP SCHEMA $schema $drop_cascade;\n"});

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

