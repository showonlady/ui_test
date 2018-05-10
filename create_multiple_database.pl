#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to create databases on odalite
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 05/24/17 - Creation


################ Documentation ################

# The SYNOPSIS section is printed out as usage when incorrect parameters
# are passed

=head1 NAME

  create_multiple_database.pl - use to create the sepecified version db on odalite

=head1 SYNOPSIS

  create_multiple_database.pl -v <db_version,eg.160419,160719,161018,170117,170418> -n_11 <number of 11g db to be created> -n_12 <number of 12c db to be created> -home_11 <number of 11g home> -home_12 <number of 12c home>


  ARGUMENTS:
   -v                 The db_version that you want to create eg.160419,160719,161018,170117,170418
   -n_11              The number of 11g db to be created, 0 is not to create
   -n_12              The number of 12c db to be created, 0 is not to create
   -home_11           The number of 11g dbhome to be created, no this option, will not create dbhome.
   -home_12           The number of 11g dbhome to be created, no this option, will not create dbhome. 
   -h                 Usage

  EXAMPLES:
   create_multiple_database.pl -v 160419 -n_11 1 -n_12 0 -home_11 2 -home_12 3

=head1 DESCRIPTION

  This script is used to create multiple databases on odalite.

=cut

################ End Documentation ################
use Getopt::Long;
use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;
use Pod::Usage;

#my $testlog = 'create_database_odalite1.log';

#open TESTLOG, ">> $testlog" || die "Can't create logfile: $!";

#select TESTLOG;
#$|=1;

# *STDOUT = *TESTLOG;
# *STDERR = *TESTLOG;

my $version;
my $num1;
my $num2;
my $home_11;
my $home_12;
my $help;
GetOptions (
            "version|v:s"      => \$version,
            "n_11:i"    => \$num1,
			"n_12:i"    => \$num2,
			"home_11:i"    => \$home_11,
			"home_12:i"    => \$home_12,
            "help|h+"               =>\$help      
                
);
if($help){
pod2usage(1);
exit 1;
}
unless (defined $version){
printf "Missing the version!\n";
pod2usage(1);
exit 1;
}

my $ODACLI="/opt/oracle/dcs/bin/odacli";
my %appliance=&describe_appliance;
my $db_edition=$appliance{"DB Edition"};
my $db_password="welcome123";
my @dataSource = (0..9,'a'..'z','A'..'Z');
my $dbname;
#$num1=4 unless (defined $num1);
#$num2=10 unless (defined $num2);

my $db_11='11.2.0.4.'.$version;
my $db_12='12.1.0.2.'.$version;
my $db_11_key;
my $db_12_key;
if($version=~/170814/){
$db_11_key=$db_11.'_x6';
$db_12_key=$db_12.'_x6';
}else{
$db_11_key=$db_11;
$db_12_key=$db_12;
}

if((defined $home_11 && $home_11>=1)||(defined $num1 && $num1>=1)){
	scp_unpack_dbclone($version_dbclone{$db_11_key}) if(!is_clone_exist($db_11));
	}
if((defined $home_12 && $home_12>=1)||(defined $num2 && $num2>=1)){
	scp_unpack_dbclone($version_dbclone{$db_12_key}) if(!is_clone_exist($db_12));
	}

if(defined $home_11 && $home_11>=1){
	for my $i(1..$home_11){
		printf "create 11204 dbhome-$i successfully!\n" if(create_dbhome($db_11));
	}
}
if(defined $home_12 && $home_12>=1){
	for my $i(1..$home_12){
		printf "create 12012 dbhome-$i successfully!\n" if(create_dbhome($db_12));
	}
}
my @Ora11gDBhome=`$ODACLI list-dbhomes|grep OraDB11204_home|grep $version|awk '{print \$1}'`;
foreach(@Ora11gDBhome){
chomp $_;
}

my @Ora12cDBhome=`$ODACLI list-dbhomes|grep OraDB12102_home|grep $version|awk '{print \$1}'`;
foreach(@Ora12cDBhome){
chomp $_;
}

my $choose_co;
my $choose_c;
my $choose_storage;

my $t;
my $Ora12cDBhome;
my $Ora11gDBhome;
my @dbtype=qw/OLTP DSS IMDB/;
my $dbtype;
my $dbtype11;
my $home_version;
if ($db_edition eq 'EE'){
if(defined $num1 && $num1>=1){
	for my $i(1..$num1){
		$choose_co=&choose_co;
		$t=time();
		$dbtype11=shuffle("OLTP", "DSS");
		$Ora11gDBhome=shuffle(@Ora11gDBhome);
		if($Ora11gDBhome){
			$home_version='-dh '.$Ora11gDBhome;
			}else{
			$home_version='-v '.$db_11;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 11204 $dbname successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl $dbtype11 $home_version $choose_co"));
		}
 }
 if(defined $num2 && $num2>=1){
	for my $i(1..$num2){
		$choose_co=&choose_co;
		$choose_c=&choose_c;
		$choose_storage=&choose_storage;
		$dbtype=shuffle(@dbtype);
		$t=time();
		$Ora12cDBhome=shuffle(@Ora12cDBhome);
		if($Ora12cDBhome){
			$home_version='-dh '.$Ora12cDBhome;
			}else{
			$home_version='-v '.$db_12;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 12102 $dbname successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl $dbtype $home_version $choose_storage $choose_c $choose_co"));
		}
	}
}elsif($db_edition eq 'SE'){
	if(($version ne 160419)&& defined $num1 && $num1>=1){
	for my $i(1..$num1){
		$choose_co=&choose_co;
		$t=time();
		$Ora11gDBhome=shuffle(@Ora11gDBhome);
		if($Ora11gDBhome){
			$home_version='-dh '.$Ora11gDBhome;
			}else{
			$home_version='-v '.$db_11;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 11204 $dbname successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl OLTP $home_version $choose_co"));
		}
	} 
	if(defined $num2 && $num2>=1){
		for my $i(1..$num2){
		$choose_co=&choose_co;
		$choose_c=&choose_c;
		$choose_storage=&choose_storage;
		$t=time();
		$Ora12cDBhome=shuffle(@Ora12cDBhome);
		if($Ora12cDBhome){
			$home_version='-dh '.$Ora12cDBhome;
			}else{
			$home_version='-v '.$db_12;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 12102 database-$i successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl OLTP $home_version $choose_storage $choose_c $choose_co"));
		}
	}
}

 
sub choose_c{
my $options='';
my $dcs_version=`rpm -qa|grep dcs-agent;`;
if($dcs_version=~/12.1.2.8/){
 if(shuffle(0..1)){
 $options=$options. "-c true ";
 }
}else{
 if(shuffle(0..1)){
 $options=$options. "-c ";
 }
}
return $options;
}

sub choose_storage{
my $options='';
if(shuffle(0..1)){
 $options=$options. "-r ASM";
 }else{
  $options=$options. "-r ACFS ";
 }
return $options;
}


sub choose_co{
my $options='';
my $dcs_version=`rpm -qa|grep dcs-agent;`;
if($dcs_version=~/12.1.2.8/){
 if(shuffle(0..1)){
 $options=$options. "-co true ";
 }
}else{
 if(shuffle(0..1)){
 $options=$options. "-co ";
 }
}
return $options;
}


# close TESTLOG;
