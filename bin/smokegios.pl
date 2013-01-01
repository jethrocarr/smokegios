#!/usr/bin/perl
#
#    SMOKEGIOS
#    Nagios to Smokeping configuration generator
#
#    Copyright (C) 2012  Jethro Carr <jethro.carr@jethrocarr.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#    USAGE:
#
#    Run with -h or --help for detailed usage information, or refer to the
#    documentation provided.
#

use strict;

use Getopt::Long;
use File::Basename;
use Log::Log4perl qw(:easy);
use Nagios::Config;

Getopt::Long::Configure('bundling');


### SETTINGS ###

# default config file
my $cfg_file = "/etc/smokegios/smokegios.conf";



### CONFIG LOAD ###

my ($opt_verbose, $opt_help, $opt_config);


# get user input

GetOptions(
	"h"	=> \$opt_help,		"help"		=> \$opt_help,
	"v"	=> \$opt_verbose,	"verbose"	=> \$opt_verbose,
	"c=s"	=> \$opt_config,	"configfile=s"	=> \$opt_config
);

# process user input
if($opt_help)
{
        print_help();
        exit;
}

if ($opt_config)
{
	$cfg_file = $opt_config;
}

if (!$cfg_file)
{
	die("A configuration file must be provided.\n");
}

if (! -e $cfg_file)
{
	die("Config file \"$cfg_file\" does not exist.\n");
}



# read in config file
my ($cfg_smokeping_config, $cfg_smokeping_reload, $cfg_nagios_config, $cfg_smokegios_log_file, $cfg_smokegios_log_debug, $cfg_smokegios_log_debug_fg);

open(CFG, $cfg_file) || die("Unable to read config file $cfg_file\n");

while (my $line = <CFG>)
{
	if ($line =~ /^smokeping_config\s*=\s*"([\S\s]*)"/)
	{
		$cfg_smokeping_config = $1;
	}

	if ($line =~ /^smokeping_reload\s*=\s*"([\S\s]*)"/)
	{
		$cfg_smokeping_reload = $1;
	}

	if ($line =~ /^nagios_config\s*=\s*"([\S\s]*)"/)
	{
		$cfg_nagios_config = $1;
	}

	if ($line =~ /^smokegios_log_file\s*=\s*"([\S\s]*)"/)
	{
		$cfg_smokegios_log_file = $1;
	}

	if ($line =~ /^smokegios_log_debug\s*=\s*"([\S\s]*)"/)
	{
		$cfg_smokegios_log_debug = $1;
	}
}

close(CFG);


# check config options
if (!$cfg_smokeping_config)
{
	die("You must set a smokeping configuration file.\n");
}

if (! -w $cfg_smokeping_config)
{
	die("Unable to open smokeping config file \"$cfg_smokeping_config\" for writing.\n");
}

if (!$cfg_smokeping_reload)
{
	die("No smokeping reload command defined, this is required to apply new configurations.\n");
}

if (!$cfg_nagios_config)
{
	die("You must set a Nagios host configuration file.\n");
}

if (! -r $cfg_nagios_config)
{
	die("Unable to open Nagios host configuration file for reading.\n");
}

if (!$cfg_smokegios_log_file)
{
	die("You must set a log file for smokegios\n");
}

if (! -w $cfg_smokegios_log_file)
{
	die("Unable to open smokegios log file for writing\n");
}

if ($opt_verbose)
{
	# write to debug log
	$cfg_smokegios_log_debug = 1;

	# write log to foreground too
	$cfg_smokegios_log_debug_fg = 1;
}



#### INIT LOGGING ####


#
# TODO: log4perl is a bit new to me, probably a smarter way todo this but the documentation was giving me a headache.
#

my %key_value_pairs = ();

if ($cfg_smokegios_log_debug_fg)
{
	# DEBUG-level, screen & log files
	%key_value_pairs = (
		"log4perl.rootLogger"					=> "DEBUG, SCREEN, LOGFILE",

		"log4perl.appender.SCREEN"				=> "Log::Log4perl::Appender::Screen",
		"log4perl.appender.SCREEN.layout"			=> "Log::Log4perl::Layout::PatternLayout",
		"log4perl.appender.SCREEN.layout.ConversionPattern"	=> "%d (line %L) %m%n",

		"log4perl.appender.LOGFILE"				=> "Log::Log4perl::Appender::File",
		"log4perl.appender.LOGFILE.filename"			=> "$cfg_smokegios_log_file",
		"log4perl.appender.LOGFILE.mode"			=> "append",
		"log4perl.appender.LOGFILE.layout"			=> "Log::Log4perl::Layout::PatternLayout",
		"log4perl.appender.LOGFILE.layout.ConversionPattern"	=> "%d %c (line %L) %m%n"
	);
}
else
{
	if ($cfg_smokegios_log_debug)
	{
		# DEBUG-level, logfile only
		%key_value_pairs = (
			"log4perl.rootLogger"					=> "DEBUG, LOGFILE",

			"log4perl.appender.LOGFILE"				=> "Log::Log4perl::Appender::File",
			"log4perl.appender.LOGFILE.filename"			=> "$cfg_smokegios_log_file",
			"log4perl.appender.LOGFILE.mode"			=> "append",
			"log4perl.appender.LOGFILE.layout"			=> "Log::Log4perl::Layout::PatternLayout",
			"log4perl.appender.LOGFILE.layout.ConversionPattern"	=> "%d %c (line %L) %m%n"
		);
	}
	else
	{
		# INFO-level, logfile only
		 %key_value_pairs = (
			"log4perl.rootLogger"					=> "INFO, LOGFILE",

			"log4perl.appender.LOGFILE"				=> "Log::Log4perl::Appender::File",
			"log4perl.appender.LOGFILE.filename"			=> "$cfg_smokegios_log_file",
			"log4perl.appender.LOGFILE.mode"			=> "append",
			"log4perl.appender.LOGFILE.layout"			=> "Log::Log4perl::Layout::PatternLayout",
			"log4perl.appender.LOGFILE.layout.ConversionPattern"	=> "%d %c %m%n"
		);
	}
}

# define logger
Log::Log4perl->init( \%key_value_pairs );
my $log = Log::Log4perl::get_logger();



#### PROGRAM ####

#
# The actual function of Smokegios is pretty simple in concept:
#
# 1. Check if the nagios hosts file is newer than the smokeping configuration file. If not, nothing todo.
# 2. Read the nagios configuration - require host & hostgroup information.
# 3. Generate appropiate smokeping configuration.
# 4. Write smokeping configuration to file in defined section. (*** Smokegios ***)
# 5. Reload smokegios.
#

$log->info("SMOKEGIOS START");


#
# Read configuration file times to determine whether or not configuration generation
# is required. Note that we need to check the nagios directory, rather than the
# config file - since the user might have changed an *included* file rather than
# the directly configured file.
#
#
my($tmp_file, $tmp_dir, $tmp_suffix)	= fileparse($cfg_nagios_config);
my $cfg_nagios_dir			= $tmp_dir;

my $time_smokeping			= (stat($cfg_smokeping_config))[9];
my $time_nagios				= (stat($cfg_nagios_dir))[9];

if ($time_nagios <= $time_smokeping)
{
	$log->info("Configurations up-to-date, nothing todo");
	$log->info("Terminated");
	exit(0);
}
else
{
	$log->info("Smokeping configurations is out of date compared to Nagios, generating new configuration");
}


#
# Read Nagios host & hostgroup information and assemble smokeping configuration
# from it.
#

my %config = {};
my $final;

my $nagios = Nagios::Config->new( Filename => $cfg_nagios_config );


if (scalar(@{ $nagios->{"host_list"} }) == 0)
{
	$log->error("Unable to read any host information from supplied nagios configuration file");
	$log->error("Make sure you are specifying the master nagios configuration file rather than a sub file");
	die("Incorrect/insufficent Nagios configuration\n");
}

if (scalar(@{ $nagios->{"hostgroup_list"} }) == 0)
{
	$log->error("Unable to read any host group information from supplied nagios configuration file");
	$log->error("Hosts need to be in a hostgroup before they will appear in Smokeping");
	die("Incorrect/insufficent Nagios configuration\n");
}



foreach my $host ( $nagios->list_hosts() )
{
	next if ( !length $host->host_name );    # avoid a bug in Nagios::Object

	$log->debug("Processing for host ". $host->host_name ."");

	
	# assemble configuration
	my $str;


	# we need to sanitise the hostname, so that it's only alphanumeric and _, so that smokeping is happy
	my $safename	= $host->host_name;
	$safename	=~ s/\W/_/g;
	$str .= "++ $safename\n";

	# menu value is best as hostname
	$str .= "menu\t= ". $host->host_name ."\n";

	# If we've specified an IP in Nagios (rather than DNS resolution), we probably care enough to have it reflected on the graph
	my $hostip;

	if ($host->address)
	{
		$hostip = "(". $host->address . ")";
	}

	# set the title to the alias
	if (!$host->alias)
	{
		$str .= "title\t= ". $host->host_name . $hostip . "\n";
	}
	else
	{
		$str .= "title\t= ". $host->alias . $hostip . "\n";
	}

	# host value - this is what smokeping actually relies on for running it's tests against.
	if (!$host->address)
	{
		# no address set - need to decide whether the hostname or alias is more address like - some sites
		# use alias for the full hostname, and host_name as the short version.
		#
		# To do this, we use DNS to lookup the alias first, if that's invalid, we fall back to using the hostname.
		#

		if (gethostbyname($host->host_name))
		{
			$str .= "host\t= ". $host->alias ."\n";
		}
		else
		{
			$str .= "host\t= ". $host->host_name ."\n";
		}
	}
	else
	{
		# nagios has an address set, just use that.
		$str .= "host\t= ". $host->address ."\n";
	}
	
	$str .= "\n";


	# save to hash
	$config{ $host->host_name } = $str;
}


foreach my $hostgroup ( $nagios->list_hostgroups() )
{
	next if ( !length $hostgroup->hostgroup_name );    # avoid a bug in Nagios::Object

	if (!$hostgroup->members)
	{
		$log->info("Host group ".$hostgroup->hostgroup_name." has no members!");
		next;
	}

	$log->debug("Processing for host group ". $hostgroup->hostgroup_name);

	# assemble configuration
	my $str;
	$str .= "\n";

	# we need to sanitise the hostgroup name, so that it's only alphanumeric and _, so that smokeping is happy
	my $safename	= $hostgroup->hostgroup_name;
	$safename	=~ s/\W/_/g;
	$str		.= "+ $safename\n";

	# use name as menu entry
	$str .= "menu\t= ". $hostgroup->hostgroup_name ."\n";
	
	# use alias for the title, otherwise group name
	if (!$hostgroup->alias)
	{
		$str .= "title\t= ". $hostgroup->hostgroup_name ."\n";
	}
	else
	{
		$str .= "title\t= ". $hostgroup->alias ."\n";
	}

	$str .= "\n";


	# add to final output
	$final .= $str;

	foreach my $hostgroup_member ( @{$hostgroup->members} )
	{
		$log->debug("Member ". $hostgroup_member->{"host_name"} ."");
		 
		# add host config to final output
		$final .= $config{ $hostgroup_member->{"host_name"} } ."\n";
	}
}


#
# Write smokeping configuration
#
# We read the configuration file and replace anything between:
#
# ### Smokegios Start ###
# <this gets replaced>
# ### Smokegios End ###
#
# This allows the admin to still change and customise any other sections of
# the Smokeping script.
#

$log->info("Writing new configuration for smokeping");

# hold config
my $config_generated;

# open original file
open(SMOKEPING_ORIG, "<$cfg_smokeping_config") || die("Unable to open smokeping configuration file for reading.\n");

my $inside = 0;
while (my $line = <SMOKEPING_ORIG>)
{
	if (!$inside)
	{
		$config_generated .= $line;
	}

	if ($line =~ /###\sSmokegios\sStart\s###/)
	{
		$inside = 1;
	}

	if ($line =~ /###\sSmokegios\sEnd\s###/)
	{
		$inside = 0;

		# add final config
		$config_generated .= $final;
		$config_generated .= $line;
	}
}

close(SMOKEPING_ORIG);


# write new file
open(SMOKEPING_NEW, ">", $cfg_smokeping_config) || die("Unable to open smokeping configuration file for writing.\n");
print SMOKEPING_NEW $config_generated;
close(SMOKEPING_NEW);



# Reload smokeping
#
$log->info("Reloading Smokeping Process");

system($cfg_smokeping_reload);

my $return = $? >> 8;

if ($return == 0)
{
	$log->info("Successfully Reloaded Smokeping");
}
else
{
	$log->error("An unexpected error occured when executing \"$cfg_smokeping_reload\"");
}



# Complete
#
$log->info("Configuration generation complete");
$log->info("Terminated");
exit(0);


## UI ASSISTANCE FUNCTIONS ##

sub print_usage()
{
        print "Usage: $0 -[hv] --configfile=<configfile>\n";
}
 
sub print_help()
{
        print "\n";
        print_usage();
        print "\n";
        print "Options:\n";
        print " -c, --configfile\n";
        print "     config file with settings\n";
	print " -h, --help\n";
        print "     print detailed help screen.\n";
        print " -v, --verbose\n";
        print "     print debug information to screen & log file.\n";
        print "\n";
        print "\n";
} 

