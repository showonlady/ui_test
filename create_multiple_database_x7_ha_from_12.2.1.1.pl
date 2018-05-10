#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to create databases on odalite x7 for ODA12.2.1.1
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 05/24/17 - Creation


################ Documentation ################

# The SYNOPSIS section is printed out as usage when incorrect parameters
# are passed

=head1 NAME

  create_multiple_database_x7_ha_from_12.2.1.1.pl - use to create the sepecified version db on oda x7-2 ha

=head1 SYNOPSIS

  create_multiple_database_x7_ha_from_12.2.1.1.pl -v <db_version,eg.170814> -n_11 <number of 11g db to be created> -n_121 <number of 12c db to be created> -n_122 <> -home_11 <number of 11g home> -home_121 <number of 12c home> -home_122 <>


  ARGUMENTS:
   -v                 The db_version that you want to create eg.160419,160719,161018,170117,170418
   -n_11              The number of 11g db to be created, 0 is not to create
   -n_121              The number of 12.1c db to be created, 0 is not to create
   -n_122              The number of 12.2c db to be created, 0 is not to create
   -home_11           The number of 11g dbhome to be created, no this option, will not create dbhome.
   -home_121          The number of 12.1c dbhome to be created, no this option, will not create dbhome. 
   -home_122          The number of 12.2c dbhome to be created, no this option, will not create dbhome. 
   -h                 Usage

  EXAMPLES:
   perl create_multiple_database_x7_ha_from_12.2.1.1.pl -v 170814 -n_11 3 -n_121 3 -n_122 3 -home_11 2 -home_121 3 -home_122 3

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
my $num3;
my $home_11;
my $home_121;
my $home_122;
my $help;
GetOptions (
            "version|v:s"      => \$version,
            "n_11:i"    => \$num1,
			"n_121:i"    => \$num2,
			"n_122:i"    => \$num3,
			"home_11:i"    => \$home_11,
			"home_121:i"    => \$home_121,
		    "home_122:i"    => \$home_122,
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
# my %appliance=&describe_appliance;
# my $db_edition=$appliance{"DB Edition"};
my $db_edition=shuffle("EE","SE");
my $db_password="WElcome12_-";
my @dataSource = (0..9,'a'..'z','A'..'Z');
my @dataSource_pdb=(@dataSource, '_');
my $dbname;
#$num1=4 unless (defined $num1);
#$num2=10 unless (defined $num2);

my $db_11='11.2.0.4.'.$version;
my $db_121='12.1.0.2.'.$version;
my $db_122='12.2.0.1.'.$version;

my $db_11_key;
my $db_121_key;
if(&is_x6 && $version=~/170814/){
$db_11_key=$db_11.'_x6';
$db_121_key=$db_121.'_x6';
}else{
$db_11_key=$db_11;
$db_121_key=$db_121;
}


if((defined $home_11 && $home_11>=1)||(defined $num1 && $num1>=1)){
	scp_unpack_dbclone($version_dbclone{$db_11_key}) if(!is_clone_exist($db_11));
	}
if((defined $home_121 && $home_121>=1)||(defined $num2 && $num2>=1)){
	scp_unpack_dbclone($version_dbclone{$db_121_key}) if(!is_clone_exist($db_121));
	}
if((defined $home_122 && $home_122>=1)||(defined $num3 && $num3>=1)){
	scp_unpack_dbclone($version_dbclone{$db_122}) if(!is_clone_exist($db_122));
	}	

if(defined $home_11 && $home_11>=1){
	for my $i(1..$home_11){
		printf "create 11204 dbhome-$i successfully!\n" if(create_dbhome($db_11));
	}
}
if(defined $home_121 && $home_121>=1){
	for my $i(1..$home_121){
		printf "create 12102 dbhome-$i successfully!\n" if(create_dbhome($db_121, $db_edition));
	}
}

if(defined $home_122 && $home_122>=1){
	for my $i(1..$home_122){
		printf "create 12201 dbhome-$i successfully!\n" if(create_dbhome($db_122, $db_edition));
	}
}


my @Ora11gDBhome=`$ODACLI list-dbhomes|grep OraDB11204_home|grep $version|awk '{print \$1}'`;
foreach(@Ora11gDBhome){
chomp $_;
}

my @Ora121cDBhome=`$ODACLI list-dbhomes|grep OraDB12102_home|grep $version|awk '{print \$1}'`;
foreach(@Ora121cDBhome){
chomp $_;
}

my @Ora122cDBhome=`$ODACLI list-dbhomes|grep OraDB12201_home|grep $version|awk '{print \$1}'`;
foreach(@Ora122cDBhome){
chomp $_;
}

my $choose_co;
my $choose_c;
my $choose_storage;
my $choose_rac_si;

my $t;
my $Ora121cDBhome;
my $Ora122cDBhome;
my $Ora11gDBhome;
my @dbtype=qw/OLTP DSS IMDB/;
my $dbtype;
my $dbtype11;
my $home_version;
if ($db_edition eq 'EE'){
if(defined $num1 && $num1>=1){
	for my $i(1..$num1){
		$choose_co=&choose_co;
		$choose_rac_si=&choose_rac_si;
		$t=time();
		$dbtype11=shuffle("OLTP", "DSS");
		$Ora11gDBhome=shuffle(@Ora11gDBhome);
		if($Ora11gDBhome){
			$home_version='-dh '.$Ora11gDBhome;
			}else{
			$home_version='-v '.$db_11;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 11204 $dbname successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl $dbtype11 $home_version $choose_co -r acfs $choose_rac_si"));
		}
 }
 if(defined $num2 && $num2>=1){
	for my $i(1..$num2){
		$choose_co=&choose_co;
		$choose_c=&choose_c;
		$choose_storage=&choose_storage;
		$dbtype=shuffle(@dbtype);
		$choose_rac_si=&choose_rac_si;
		$t=time();
		$Ora121cDBhome=shuffle(@Ora121cDBhome);
		if($Ora121cDBhome){
			$home_version='-dh '.$Ora121cDBhome;
			}else{
			$home_version='-v '.$db_121;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 12102 $dbname successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl $dbtype $home_version $choose_storage $choose_c $choose_co $choose_rac_si"));
		}
	}
	
	if(defined $num3 && $num3>=1){
	for my $i(1..$num3){
		$choose_co=&choose_co;
		$choose_c=&choose_c;
		$choose_storage=&choose_storage;
		$dbtype=shuffle(@dbtype);
		$choose_rac_si=&choose_rac_si;
		$t=time();
		$Ora122cDBhome=shuffle(@Ora122cDBhome);
		if($Ora122cDBhome){
			$home_version='-dh '.$Ora122cDBhome;
			}else{
			$home_version='-v '.$db_122;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 12201 $dbname successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl $dbtype $home_version $choose_storage $choose_c $choose_co $choose_rac_si"));
		}
	}
	
}elsif($db_edition eq 'SE'){
	if(($version ne 160419)&& defined $num1 && $num1>=1){
	for my $i(1..$num1){
		$choose_co=&choose_co;
		$choose_rac_si=&choose_rac_si;
		$t=time();
		$Ora11gDBhome=shuffle(@Ora11gDBhome);
		if($Ora11gDBhome){
			$home_version='-dh '.$Ora11gDBhome;
			}else{
			$home_version='-v '.$db_11;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 11204 $dbname successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl OLTP $home_version $choose_co -r acfs $choose_rac_si"));
		}
	} 
	if(defined $num2 && $num2>=1){
		for my $i(1..$num2){
		$choose_co=&choose_co;
		$choose_c=&choose_c;
		$choose_storage=&choose_storage;
		$choose_rac_si=&choose_rac_si;
		$t=time();
		$Ora121cDBhome=shuffle(@Ora121cDBhome);
		if($Ora121cDBhome){
			$home_version='-dh '.$Ora121cDBhome;
			}else{
			$home_version='-v '.$db_121;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 12102 database-$i successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl OLTP $home_version $choose_storage $choose_c $choose_co $choose_rac_si"));
		}
	}
	if(defined $num3 && $num3>=1){
		for my $i(1..$num3){
		$choose_co=&choose_co;
		$choose_c=&choose_c;
		$choose_storage=&choose_storage;
		$choose_rac_si=&choose_rac_si;
		$t=time();
		$Ora122cDBhome=shuffle(@Ora122cDBhome);
		if($Ora122cDBhome){
			$home_version='-dh '.$Ora122cDBhome;
			}else{
			$home_version='-v '.$db_122;
			}
		$dbname=name_generate(@dataSource, '8');
		print "create 12201 database-$i successfully!Time is:".(time()-$t)."\n" if(create_database($dbname, $db_password, "-cl OLTP $home_version $choose_storage $choose_c $choose_co $choose_rac_si"));
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
  my $pdbname=name_generate(@dataSource_pdb, '30');
  $options=$options. "-p $pdbname";
        
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

sub choose_rac_si{
my $options='';
my $db_type=shuffle("rac","si","racone");
$options=$options."-y $db_type";
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

sub is_x6{
my $output=`cat /proc/cmdline`;
if ($output=~/x6-2/i){
return 1;
}else{
return 0;
}
}

# close TESTLOG;
