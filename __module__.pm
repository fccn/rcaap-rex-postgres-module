package Rex::Module::Database::Postgres;

use Rex -base;

use Rex::Commands::User;
use Data::Dumper;

our $__configuration = { 
	user => 'postgres',
	data_dir => '/var/lib/pgsql/data',
	log_dir => '/var/log/postgresql',
	locale => 'en_US.UTF8',
	encoding => 'UTF8',
	#authmethod => 'md5',
};

our @__hba = (
	{ 
		type => 'host',
		database => 'all',
		user => 'all',
		address => '127.0.0.1/32',
		method => 'md5'
	},
	{ 
		type => 'host',
		database => 'all',
		user => 'all',
		address => '::1/128',
		method => 'md5'
	}	
);

our $__bin_path = { 
	debian => "/usr/bin",
	ubuntu => "/usr/bin",
	centos => "/usr/bin",
	mageia => "/usr/bin",
};

our $__service_name = { 
	debian => "postgresql",
	ubuntu => "postgresql",
	centos => "postgresql",
	mageia => "postgresql",
};

our $__package_name = { 
	debian => "postgresql",
	ubuntu => "postgresql",
	centos => "postgresql-server",
	mageia => "postgresql",
};

our $__contrib_package_name = { 
	debian => "postgresql-contrib",
	ubuntu => "postgresql-contrib",
	centos => "postgresql-contrib",
	mageia => "postgresql-contrib", 
};


task 'setup',
	sub {	
		my $package_name = param_lookup ("package_name", case ( lc(operating_system), $__package_name ));
		my $contrib_package_name = param_lookup ("contrib_package_name", case ( lc(operating_system), $__contrib_package_name ));

		update_package_db;
		my $os = get_operating_system();
		pkg $package_name, ensure    => "latest";	
		pkg $contrib_package_name, ensure    => "latest";
	};


task 'initialize',
	sub {	
		my $postgres_service = param_lookup ("service_name", case ( lc(operating_system), $__service_name ));
		initialize_folders ();
		initialize_service ();
		apply_templates();
		
		#if ($changed) {
		#	restart();	
		#}
		# Service Setup
		run "systemctl enable $postgres_service";
		die("Error enabling service") unless ($? == 0); 

	};

my @service_actions = qw( start stop restart );
foreach my $service_action (@service_actions) {
	task "$service_action" => sub {
		my $postgres_service = param_lookup ("service_name", case ( lc(operating_system), $__service_name ));
		service $postgres_service => "$service_action";
	};
}

sub postgresql_psql {
	my $postgres_bin_path = param_lookup ("bin_path", case ( lc(operating_system), $__bin_path ));
	my ($user,$password,$host,$db_stmt,$filename) = @_;
	return run $postgres_bin_path."/psql -U $user -h $host $db_stmt < $filename",
				env => {
					PGPASSWORD => "$password",
				};
};

# postgresql_sudo_psql: to execute psql command using postgres user
# @sql_query is a string with the SQL query to execute
# @db_stmt is a string with the name of the database
sub postgresql_sudo_psql {
	my $postgres_config = param_lookup ("configuration", $__configuration);
    my $postgres_bin_path = param_lookup ("bin_path", case ( lc(operating_system), $__bin_path ));

	my $os = get_operating_system();
	my $sql_query = shift;
	die("Error missing sql query for psql") unless ($sql_query); 
	my $db_stmt = shift;
	my $user = $postgres_config->{user};
	
	sudo { 
		command => $postgres_bin_path."/psql $db_stmt -c \"$sql_query\"", 
		user => $user,
	};
	die("Error on psql -c $sql_query") unless ($? == 0); 
};

sub initialize_service {
	my $postgres_config = param_lookup ("configuration", $__configuration);
	my $postgres_bin_path = param_lookup ("bin_path", case ( lc(operating_system), $__bin_path ));

	my $locale = $postgres_config->{locale};
	my $encoding = $postgres_config->{encoding};
	my $user = $postgres_config->{user};	
	my $data_dir =  $postgres_config->{data_dir};	
	my $log_dir = $postgres_config->{log_dir};
	my $os = get_operating_system();
	
	# Create a new PostgreSQL database cluster
	run $postgres_bin_path ."/postgresql-setup initdb",
		continuous_read => sub {
			#output to log
			Rex::Logger::info(@_, "warn");
		},
		env => {
			PGSETUP_INITDB_OPTIONS => "--encoding=$encoding --locale=$locale --pgdata=$data_dir",
			PGDATA => "$data_dir",
		};
	die("Error on 'postgresql-setup initdb' command.") unless ($? == 0); 
	
};


sub initialize_folders {
	my $postgres_config = param_lookup ("configuration", $__configuration);
	my $user = $postgres_config->{user};	
	my $data_dir =  $postgres_config->{data_dir};	
	my $log_dir = $postgres_config->{log_dir};
	# mv data dir to tmp dir
	if (is_dir($data_dir)) {
		file $data_dir."_old", ensure => "absent";
		mv ($data_dir, $data_dir."_old");
	}
	
	file $log_dir, ensure => "directory",
		owner  => $user;
	
};

sub apply_templates {
	my $postgres_config = param_lookup ("configuration", $__configuration);
	my $postgres_hba = param_lookup ("hba", \@__hba);
	my $data_dir =  $postgres_config->{data_dir};
	file "$data_dir/postgresql.conf",
	  content   => template("templates/postgresql.conf.tpl");
	  
	file "$data_dir/pg_hba.conf",
	  content   => template("templates/pg_hba.conf.tpl", hba => $postgres_hba);	
};

sub isInstalled {
	return is_installed(param_lookup ("package_name", case ( lc(operating_system()), $__package_name )));
}

1;

=pod

=head1 NAME

$::module_name - {{ SHORT DESCRIPTION }}

=head1 DESCRIPTION

{{ LONG DESCRIPTION }}

=head1 USAGE

{{ USAGE DESCRIPTION }}

 include qw/Rex::Module::Database::Postgres/;

 task yourtask => sub {
    Rex::Module::Database::Postgres::setup();
 };

=head1 TASKS

=over 4

=item example

This is an example Task. This task just output's the uptime of the system.

=back

=cut
