use Getopt::Long;
use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;
my $testlog = 'create_database_odalite1.log';

open TESTLOG, ">> $testlog" || die "Can't create logfile: $!";

#select TESTLOG;
#$|=1;

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;

my $ODACLI="/opt/oracle/dcs/bin/odacli";
my %appliance=&describe_appliance;
my $db_edition=$appliance{"DB Edition"};
my $db_password="welcome123";
my $num1;
my $num2;

die "please give the version, i.e.160419,160719!\n" unless(defined $ARGV[0]);
if(defined $ARGV[1]){
	$num1=$ARGV[1];
	}else{
	$num1=4;
	}
if(defined $ARGV[2]){
	$num2=$ARGV[2];
	}else{
	$num2=10;
	}

my $db_11='11.2.0.4.'.$ARGV[0];
scp_unpack_dbclone($version_dbclone{$db_11}) if(!is_clone_exist($db_11));
for my $i(1..2){
printf "create 11204 dbhome-$i successfully!\n" if(create_dbhome($db_11));
}
my $i ='$1';
my @Ora11gDBhome=`$ODACLI list-dbhomes|grep OraDB11204_home|awk '{print $i}'`;
foreach(@Ora11gDBhome){
chomp $_;
}
my $db_12='12.1.0.2.'.$ARGV[0];
scp_unpack_dbclone($version_dbclone{$db_12}) if(!is_clone_exist($db_12));
for my $i(1..3){
printf "create 12012 dbhome-$i successfully!\n" if(create_dbhome($db_12));
}

my @Ora12gDBhome=`$ODACLI list-dbhomes|grep OraDB12102_home|awk '{print $i}'`;
foreach(@Ora12gDBhome){
chomp $_;
}

my $choose_co;
my $choose_c;
my $choose_storage;

my $t;
my $Ora12gDBhome;
my $Ora11gDBhome;
my @dbtype=qw/OLTP DSS IMDB/;
my $dbtype;
my $dbtype11;
if ($db_edition eq 'EE'){
for my $i(1..$num1){
	$choose_co=&choose_co;
	$t=time();
	$dbtype11=shuffle("OLTP", "DSS");
	$Ora11gDBhome=shuffle(@Ora11gDBhome);
	print "create 11204 database-$i successfully!Time is:".(time()-$t)."\n" if(create_database("my11db$i", $db_password, "-cl $dbtype11 -dh $Ora11gDBhome $choose_co"));
	}
 
for my $i(1..$num2){
	$choose_co=&choose_co;
	$choose_c=&choose_c;
	$choose_storage=&choose_storage;
	$dbtype=shuffle(@dbtype);
	$t=time();
	$Ora12gDBhome=shuffle(@Ora12gDBhome);
	print "create 12102 database-$i successfully!Time is:".(time()-$t)."\n" if(create_database("my12db$i", $db_password, "-cl $dbtype -dh $Ora12gDBhome $choose_storage $choose_c $choose_co"));
	}
}elsif($db_edition eq 'SE'){
	if($ARGV[0] ne 160419){
	for my $i(1..$num1){
		$choose_co=&choose_co;
		$t=time();
		$Ora11gDBhome=shuffle(@Ora11gDBhome);
		print "create 11204 database-$i successfully!Time is:".(time()-$t)."\n" if(create_database("my11db$i", $db_password, "-cl OLTP -dh $Ora11gDBhome $choose_co"));
		}
	} 

for my $i(1..$num2){
	$choose_co=&choose_co;
	$choose_c=&choose_c;
	$choose_storage=&choose_storage;
	$t=time();
	$Ora12gDBhome=shuffle(@Ora12gDBhome);
	print "create 12102 database-$i successfully!Time is:".(time()-$t)."\n" if(create_database("my12db$i", $db_password, "-cl OLTP -dh $Ora12gDBhome $choose_storage $choose_c $choose_co"));
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


close TESTLOG;
