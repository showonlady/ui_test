#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to downgrade ilom and bios
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/26/16 - Creation

################ Documentation ################

# The SYNOPSIS section is printed out as usage when incorrect parameters
# are passed

=head1 NAME

  downgrade_ilom.pl - use to downgrade the ilom and bios.

=head1 SYNOPSIS

  downgrade_ilom.pl -e 12.1.2.8_ODALITEM -host <hostname> -u <username> -p <user password>


  ARGUMENTS:
   -e                 The env_hw, eg. 12.1.2.7_V2,12.1.2.8_V4, 12.1.2.8.1_HA
   -host              Hostname
   -u                 User name, root
   -p                 User password, changeme, welcome1
   -h                 Usage

  EXAMPLES:
   downgrade_ilom.pl -e 12.1.2.8_ODALiteM -host rwsoda6m005-c -u root -p changeme

=head1 DESCRIPTION

  This script is used to downgrade ilom and bios.

=cut

################ End Documentation ################
use Getopt::Long;
use strict ;
use warnings ;
use English ;
use Expect;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;
use Pod::Usage;

my %version_ILOM=("12.1.2.6_V2"=>"ODA12.1.2.6-ILOM-3_2_4_26_b_r101722-Sun_Fire_4170_M3.pkg",
"12.1.2.6_V3"=>"ODA12.1.2.6-ILOM-3_2_4_46_a_r101689-Sun_Server_X4-2.pkg",
"12.1.2.6_V4"=>"ODA12.1.2.6-ILOM-3_2_4_52_r101649-Oracle_Server_X5-2.pkg",
"12.1.2.7_V2"=>"ODA12.1.2.7-ILOM-3_2_4_76_r108980-Sun_Fire_4170_M3.pkg",
"12.1.2.7_V3"=>"ODA12.1.2.7-ILOM-3_2_4_72_r108978-Sun_Server_X4-2.pkg",
"12.1.2.7_V4"=>"ODA12.1.2.7-ILOM-3_2_4_68_r108889-Oracle_Server_X5-2.pkg",
"12.1.2.8_V2"=>"ODA12.1.2.7-ILOM-3_2_4_76_r108980-Sun_Fire_4170_M3.pkg",
"12.1.2.8_V3"=>"ODA12.1.2.7-ILOM-3_2_4_72_r108978-Sun_Server_X4-2.pkg",
"12.1.2.8_V4"=>"ODA12.1.2.8-ILOM-3_2_4_80_r110636-Oracle_Server_X5-2.pkg",
"12.1.2.8.1_HA"=>"ODAHA12.1.1.8.1_ILOM-3_2_6_46_r110665-Oracle_Server_X6-2.pkg",
"12.1.2.9_V2"=>"ODA12.1.2.9-ILOM-3_2_7_32_a_r112581-Sun_Fire_X4170_M3.pkg",
"12.1.2.9_V3"=>"ODA12.1.2.9-ILOM-3_2_7_32_a_r112581-Sun_Server_X4-2.pkg",
"12.1.2.9_V4"=>"ODA12.1.2.9-ILOM-3_2_7_26_a_r112579-Oracle_Server_X5-2.pkg",
"12.1.2.9_HA"=>"ODAHA12.1.2.9-ILOM-3_2_7_26_a_r112632-Oracle_Server_X6-2.pkg",
"12.1.2.8_ODALITES"=>"ODALite12.1.2.8-ILOM-3_2_6_24_r107041-Oracle_Server_X6-2.pkg",
"12.1.2.8_ODALITEM"=>"ODALite12.1.2.8-ILOM-3_2_6_24_r107041-Oracle_Server_X6-2.pkg",
"12.1.2.8.1_ODALITEL"=>"ODALite12.1.2.8.1-ILOM-3_2_6_48_r110666-Oracle_Server_X6-2L.pkg",
);       
my $env_hw;
my $hostname;
my $username;
my $password;
my $help;
GetOptions (
            "env|e:s"      => \$env_hw,
            "host:s"    => \$hostname,
            "user|u:s"    =>  \$username,
            "password|p:s"     =>   \$password,
            "help|h+"               =>\$help

);
if($help){
pod2usage(1);
exit 1;
}
unless (defined $env_hw && defined $hostname && defined $password && defined $username){
printf "Missing arguments!\n";
pod2usage(1);
exit 1;
}
$env_hw=~tr/a-z/A-z/;
my $path="/home/chqin/qcl/BIOS-ILOM-CPLD-FW/ILOM/";
my $ilom=$version_ILOM{$env_hw};
die "-e was not correct!\n" unless (defined $ilom);
my $file=$path.$version_ILOM{$env_hw};
#printf "$ilom\n";
scp_file($file);
`ipmitool  -I lanplus -U $username -P $password -H $hostname chassis power off`;
`ipmiflash -I lanplus -U $username -P $password -H $hostname write $ilom`;
sleep 300;
`ipmitool  -I lanplus -U $username -P $password -H $hostname chassis power on`;

my @result;
&check_ilom($hostname,$password);

open RESULT, "spinfo" || die "no spinfo file!\n";
while(my $line=<RESULT>){
  if($line=~/system_description/){
     chomp $line;
     @result=split /,\s*/, $line;
     last;
  }
}      
close RESULT;
my $result=join '_',@result[1..2];
$result=~s/\./_/g;
$result=~s/\s*v/-/;
printf "downgrade ilom successfully\n" if($ilom=~/$result/);
`rm -rf $ilom`;

sub scp_file{
my $file=$_[0];
my $server=$_[1];
my $server_password=$_[2];
$server='10.208.144.25' unless (defined $server);
$server_password='welcome2' unless (defined $server_password);
#printf "$server, $server_password\n";

my $cmd="/usr/bin/scp $server:$file .";

my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
my $pass=$exp->expect($timeout, 'continue connecting');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'password');
$exp->send("$server_password\r") if($pass);
$exp->interact();
}

sub check_ilom{

my $hostname=shift;
my $password=shift;

my $cmd="ssh -l root $hostname ls /SP>spinfo";

my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
my $pass=$exp->expect($timeout, '(yes/no)');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'Password');
$exp->send("$password\r") if($pass);
$exp->interact() if($pass);
}
