#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used patch odalite to the defined version, supported version is 12.1.2.9 and above.
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 02/08/17 - Creation
# - CHQIN 12/29/17 - Modifition add x7-2 ha patch

use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;



die "please give the version, i.e.12.1.2.9.0!\n" unless(defined $ARGV[0]);
my $version=$ARGV[0];
my @version=split /\./, $version;
my $ver_dir=join '.', @version[0..3];
$ver_dir=('ODA'.$ver_dir);
printf "$ver_dir\n";
my $patch_location="/chqin/$ver_dir/patch/*";


my $dir='/root/patch';
`mkdir -p $dir`;
my $dcs_version=`rpm -qa|grep dcs-agent`;

&scp_file($patch_location, $dir);

my $patch_file=`ls -l $dir|awk '{print \$9}'`;
$patch_file=~s/^\s*//;
$patch_file=~s/\s*$//;
my @patch_file=split /\n/,$patch_file;


if(&is_x7ha && $dcs_version=~/12.2.1.1/){
    scp_file2("$dir/oda-sm*");
	&update_repository2(@patch_file);
	}
sleep 300;

foreach (@patch_file){

	chomp $_;
	my $patch_file="$dir/$_";
	if(update_repository($patch_file)){
	  `rm -rf $patch_file`;
	   }else{
	   die "update_repository failed!\n";
	   	} 
  }
die "dcsagent update failed!\n" unless(update_dcsagent($version));
sleep 360;
die "server patch failed!\n" unless(update_server($version));


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
`rm -rf update_patch.sh`;
foreach(@_){
`echo "/opt/oracle/dcs/bin/odacli update-repository -f /root/$_;" >>update_patch.sh`;
}
scp_file2("update_patch.sh");
my $cmd='ssh 192.168.16.25 "sh update_patch.sh"';
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






