#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to deploy the oda x7-2 12.2.1.1 or later
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/14/17 - Creation


################ Documentation ################

# The SYNOPSIS section is printed out as usage when incorrect parameters
# are passed

=head1 NAME

  odax7deploy_from_12.2.1.1.pl - use to deploy oda x7-2 for odalite and odaha

=head1 SYNOPSIS

  odax7deploy_from_12.2.1.1.pl -v 12.2.1.1 -o <path of json file> -s <server name> -p <server password>


  ARGUMENTS:
   -v                 The version that you want to deploy, 12.2.1.1
   -o                 Abslute patch of json file
   -s                 Server name which json file is located
   -p                 Server password
   -h                 Usage 

  EXAMPLES:
   perl odax7deploy_from_12.2.1.1.pl -v 12.2.1.1 -o /scratch/chqin/json/scaoda7s005.json -s 10.208.184.63 -p welcome2
   perl odax7deploy_from_12.2.1.1.pl -v 12.2.1.1 -o /scratch/chqin/json/scaoda704.json.12.2.1.1 -s 10.208.184.63 -p welcome2
   perl odax7deploy_from_12.2.1.1.pl -v 18.1.0.0 -o /scratch/chqin/json/scaoda7s005.json_18.1 -s 10.208.184.63 -p welcome2
   perl odax7deploy_from_12.2.1.1.pl -v 18.1.0.0 -o /scratch/chqin/json/rwsoda6m005.json_18.1 -s 10.208.184.63 -p welcome2
   perl odax7deploy_from_12.2.1.1.pl -v 18.1.0.0 -o /scratch/chqin/json/rwsoda6f004.json_18.1 -s 10.208.184.63 -p welcome2


=head1 DESCRIPTION

  This script is used to deploy oda x7-2

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

my $testlog = 'oda_x7_deploy.log';

open TESTLOG, ">> $testlog" || die "Can't create logfile: $!";

#select TESTLOG;
#$|=1;

#*STDOUT = *TESTLOG;
#*STDERR = *TESTLOG;

my $version;
my $jsonfile;
my $server_name;
my $password;
my $help;
GetOptions (
            "version|v:s"      => \$version,
            "onecmd|o:s"    => \$jsonfile,
            "server|s:s"    =>  \$server_name,         
            "password|p:s"     =>   \$password,
            "help|h+"               =>\$help      
                
);
if($help){
pod2usage(1);
exit 1;
}
unless (defined $version && defined $jsonfile){
printf "Missing the version or jsonfile!\n";
pod2usage(1);
exit 1;
}

$server_name="10.208.144.25" unless (defined $server_name);
$password="welcome2" unless (defined $password);

our $dir='/tmp/tmp';
`mkdir -p $dir`;
my $oda_sm_location;
my @version=split /\./, $version;
my $ver_dir=join '.', @version[0..3];
$ver_dir=('ODA'.$ver_dir);
printf "$ver_dir\n";

if($version=~/18.1.0.0/){
	$oda_sm_location="/chqin/$ver_dir/oda-sm/*";
	printf "$oda_sm_location\n";
	&scp_file($oda_sm_location,'10.208.184.63', 'welcome2');
}else{
    $oda_sm_location="/chqin/$ver_dir/oda-sm/*";
	printf "$oda_sm_location\n";
	&scp_file($oda_sm_location);
}


if(&is_x7ha && $version=~/12.2.1.1/){
    scp_file2("$dir/oda-sm*");
	&update_repository2;
	}

	
my $flag1='$9';
my @oda_sm_files=`ls -l $dir/oda*|awk '{print $flag1}'`;
foreach (@oda_sm_files){
chomp;
if(update_repository($_)){
  `rm -rf $_`;
   }else{
   die "update_repository failed!\n";
   }
}

if($version=~/12.2.1.1/){
die "dcsagent update failed!\n" unless(update_dcsagent($version));
sleep 360;
die "server patch failed!\n" unless(update_server($version));
sleep 120;
}

scp_file($jsonfile, $server_name, $password);
my $json_file=basename $jsonfile;
printf "$json_file\n";
#if(create_appliance("$dir/$json_file")){
create_appliance("$dir/$json_file");


sub scp_file{

my $file=$_[0];
my $server=$_[1];
my $server_password=$_[2];
$server='10.208.144.25' unless (defined $server);
$server_password='welcome2' unless (defined $server_password);
printf "$server, $server_password\n";

my $cmd="/usr/bin/scp $server:$file $dir";

my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
my $pass=$exp->expect($timeout, 'continue connecting');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'password');
$exp->send("$server_password\r") if($pass);
$exp->interact();
}

sub scp_file2{

my $file=$_[0];
my $cmd="/usr/bin/scp $file 192.168.16.25:/root";

my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
my $pass=$exp->expect($timeout, 'continue connecting');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'password');
$exp->send("welcome1\r") if($pass);
$exp->interact();
}

sub update_repository2{
my $password="welcome1";
`echo "/opt/oracle/dcs/bin/odacli update-repository -f /root/oda-sm-12.2.1.1.0-170924-GI-12.2.1.1.zip,/root/oda-sm-12.2.1.1.0-171025-DB-12.2.1.1.zip,/root/oda-sm-12.2.1.1.0-171026-DB-11.2.0.4.zip,/root/oda-sm-12.2.1.1.0-171026-DB-12.1.0.2.zip,/root/oda-sm-12.2.1.1.0-171031-server.zip" >update_repository.sh`;
scp_file2("update_repository.sh");
my $cmd='ssh 192.168.16.25 "sh update_repository.sh"';
my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
my $pass=$exp->expect($timeout, '(yes/no)');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'password');
$exp->send("$password\r") if($pass);
$exp->interact() if($pass);
}

sub is_x7ha{
my $output=`cat /proc/cmdline`;
if ($output=~/HA/i){
return 1;
}else{
return 0;
}
}
close TESTLOG;


