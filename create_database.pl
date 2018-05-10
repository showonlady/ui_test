use Getopt::Long;
use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;
my $testlog = 'create_database_odalite.log';

open TESTLOG, "> $testlog" || die "Can't create logfile: $!";

#select TESTLOG;
#$|=1;

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;

my $ODACLI="/opt/oracle/dcs/bin/odacli";
my %appliance=&describe_appliance;
my $db_edition=$appliance{"DB Edition"};
my $db_password="welcome123";

die "please give the version, i.e.160419,160719!\n" unless(defined $ARGV[0]);


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

if ($db_edition eq 'EE'){
 $choose_co=&choose_co;
print "create 11204 database-1 successfully!\n" if(create_database("my11db1", $db_password, "-cl DSS -dh $Ora11gDBhome[0] $choose_co"));
 $choose_co=&choose_co;
print "create 11204 database-2 successfully!\n" if(create_database("my11db2", $db_password, "-cl OLTP -dh $Ora11gDBhome[0] $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-1 successfully!\n" if(create_database("my12db1", $db_password, "-cl OLTP -dh $Ora12gDBhome[0] -r ASM $choose_c $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-2 successfully!\n" if(create_database("my12db2", $db_password, "-cl OLTP -dh $Ora12gDBhome[0] -r ACFS $choose_c $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-3 successfully!\n" if(create_database("my12db3", $db_password, "-cl DSS -dh $Ora12gDBhome[0] -r ASM $choose_c $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-4 successfully!\n" if(create_database("my12db4", $db_password, "-cl DSS -dh $Ora12gDBhome[1] -r ACFS $choose_c $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-5 successfully!\n" if(create_database("my12db5", $db_password, "-cl IMDB -dh $Ora12gDBhome[1] -r ASM $choose_c $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-6 successfully!\n" if(create_database("my12db6", $db_password, "-cl IMDB -dh $Ora12gDBhome[1] -r ACFS $choose_c $choose_co"));
}elsif($db_edition eq 'SE'){
if(!$ARGV[0]=~/160419/){
 $choose_co=&choose_co;
print "create 11204 database-1 successfully!\n" if(create_database("my11db1", $db_password, "-cl OLTP -dh $Ora11gDBhome[0] $choose_co"));
 $choose_co=&choose_co;
print "create 11204 database-2 successfully!\n" if(create_database("my11db2", $db_password, "-cl OLTP -dh $Ora11gDBhome[0] $choose_co"));
} 
$choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-1 successfully!\n" if(create_database("my12db1", $db_password, "-cl OLTP -dh $Ora12gDBhome[0] -r ASM $choose_c $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-2 successfully!\n" if(create_database("my12db2", $db_password, "-cl OLTP -dh $Ora12gDBhome[0] -r ACFS $choose_c $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-3 successfully!\n" if(create_database("my12db3", $db_password, "-cl OLTP -dh $Ora12gDBhome[1] -r ASM $choose_c $choose_co"));
 $choose_co=&choose_co;
 $choose_c=&choose_c;
print "create 12102 database-4 successfully!\n" if(create_database("my12db4", $db_password, "-cl OLTP -dh $Ora12gDBhome[1] -r ACFS $choose_c $choose_co"));
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
