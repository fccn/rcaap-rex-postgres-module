package Rex::Module::Database::Postgres::Admin::User;
   
use strict;
use warnings;

use Rex -base;
use Rex::Module::Database::Postgres::Admin;

task create => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{user};
   die("You have to specify the users password.") unless $param->{password};
  
   my $user     = $param->{user};
   my $password = $param->{password};
   my $role = $param->{role} || "";
   my $password_stmt = (defined ($param->{encrypted_password}) && $param->{encrypted_password} eq 'true') ? "ENCRYPTED PASSWORD '$password'" : "PASSWORD '$password'";

   Rex::Module::Database::Postgres::Admin::execute({sql => "CREATE USER $user WITH $role $password_stmt ;\n"});

};

desc "Drops a user - Only works if user has no dependencies";
task drop => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{name};
   
   my $user      = $param->{name};

  Rex::Module::Database::Postgres::Admin::execute({sql => "DROP USER $user;"});

};


desc "change user roles";
task drop_role => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{user};

   my $user      = $param->{user};

  Rex::Module::Database::Postgres::Admin::execute({sql => "DROP ROLE $user;"});

};

desc "change user roles - roles can be added wiht spaces like CREATEDB CREATEUSER ...";
task add_role => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{user};
   die("You have to specify the user role.") unless $param->{role};

   my $user      = $param->{user};
   my $role      = $param->{role};


  Rex::Module::Database::Postgres::Admin::execute({sql => "ALTER ROLE $user $role"});

};

desc "change user roles - roles can be added wiht spaces like CREATEDB CREATEUSER ...";
task create_role => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{user};
   die("You have to specify the user role.") unless $param->{role};

   my $user      = $param->{user};
   my $role      = $param->{role};


  Rex::Module::Database::Postgres::Admin::execute({sql => "CREATE ROLE $user $role"});

};

desc "grants user access";
task grant => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{user};
   die("You have to specify the users password.") unless $param->{password};
  
   my $user     = $param->{user};   
   my $name     = $param->{name};
   my $rights   = $param->{rights};
   my $schema   = $param->{schema};   

   Rex::Module::Database::Postgres::Admin::execute({sql => "REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;", db=>$name});
   Rex::Module::Database::Postgres::Admin::execute({sql => "GRANT CONNECT ON DATABASE $name TO $user;", db=>$name});
   Rex::Module::Database::Postgres::Admin::execute({sql => "GRANT $rights ON ALL TABLES IN SCHEMA public TO $user;", db=>$name});
};

desc "revokes user access";
task revoke => sub {

   my $param = shift;
   die("You have to specify the user name.") unless $param->{name};
   
   my $user      = $param->{name};
   my $name     = $param->{name};

  Rex::Module::Database::Postgres::Admin::execute({sql => "REVOKE ALL PRIVILEGES ON $name FROM $user;", db=>$name});

};

1;

=pod

=head1 NAME

Rex::Module::Database::Postgres::Admin::User - Manage Postgres User

=head1 USAGE

 task "taskname", sub {
    Rex::Module::Database::Postgres::Admin::User::create({
       user     => "foo",
       host     => "host",
       password => "password",
       rights   => "SELECT,INSERT",
       schema   => "foo.*",
    });
     
    Rex::Module::Database::Postgres::Admin::User::drop({
       user       => "foo",
       host       => "host",
       delete_all => "if empty not executed",
    });
 };

