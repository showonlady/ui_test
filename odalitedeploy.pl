#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to deploy the odalite and create some databases
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/17/16 - Creation


################ Documentation ################

# The SYNOPSIS section is printed out as usage when incorrect parameters
# are passed

=head1 NAME

  odalitedeploy.pl - use to deploy odalite

=head1 SYNOPSIS

  odalitedeploy.pl -v 12.1.2.8 -o <path of json file> -s <server name> -p <server password>


  ARGUMENTS:
   -v                 The version that you want to deploy, 12.1.2.8,12.1.2.8.1,12.1.2.9
   -o                 Abslute patch of json file
   -s                 Server name which json file is located
   -p                 Server password
   -h                 Usage 

  EXAMPLES:
  perl odalitedeploy.pl -v 12.1.2.8.1 -o /home/chqin/qcl/onecmd.params/rwsoda6f004.json.input
  perl odalitedeploy.pl -v 12.1.2.12 -o /home/chqin/qcl/onecmd.params/rwsoda6m005.json.input.oneuser 

=head1 DESCRIPTION

  This script is used to deploy odalite

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

my $testlog = 'odalite_deploy.log';

#open TESTLOG, ">> $testlog" || die "Can't create logfile: $!";

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
$oda_sm_location="/chqin/$ver_dir/oda-sm/*";

printf "$oda_sm_location\n";
&scp_file($oda_sm_location);

if($version=~/12.1.2.8.1/){
scp_file("/chqin/ODA12.1.2.8.1/dcsImage_12.1.2.8.1.zip");
`update-image --image-files $dir/dcsImage_12.1.2.8.1.zip`;
sleep 120;
}
my $flag1='$9';
my @oda_sm_files=`ls -l $dir/oda-sm*|awk '{print $flag1}'`;
foreach (@oda_sm_files){
chomp;
if(update_repository($_)){
  `rm -rf $_`;
   }else{
   die "update_repository failed!\n";
   }
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

#close TESTLOG;


