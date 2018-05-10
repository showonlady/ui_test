#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to create multiple dbs on ODA (1 11.2.0.3, 3 11.2.0.4, 3 12.1.0.2), we can sepecify the db version
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 01/11/16 - Creation


use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
our $OAKCLI_HOME='/opt/oracle/oak/bin';
my $root_password="welcome1";
my $sysasm_password="welcome1";

if (! open LOG, ">logfile"){
die "Cannot create logfile: $!";
}
select LOG;
$|=1;
my @db_version;

if(!open VERSION, "version"){
die "no version file:$!";
}
while (<VERSION>){
chomp;
push(@db_version, $_);
}
my $db_version_12102=$db_version[0];
my $db_version_11204=$db_version[1];
printf "$db_version_11204\n,$db_version_12102\n";

my @db_type2=('1','2','3');
my $db_type1;
my $db_type2;
my $ee_node;
my $db_class=1;
my $db_name;
my $cmd;

&unpack_db_clonefile($db_version_12102);

foreach (@db_type2){

$db_type2=$_;
$db_type1=shuffle('1','2','3');
$db_name="q12102$db_type2";
$cmd="$OAKCLI_HOME/oakcli create database -db $db_name -version $db_version_12102";
printf "$cmd\n";

if($db_type2 eq '1'){
$ee_node=shuffle('1','2');
printf "Database type:$db_type1, Database Deployment:$db_type2, Node Number:$ee_node, Database Class:$db_class\n";
&create_db($cmd, $root_password, $sysasm_password, $db_type1, $db_type2,$db_class, $ee_node);
}else{
printf "Database type:$db_type1, Database Deployment:$db_type2, Database Class:$db_class\n";
&create_db($cmd, $root_password, $sysasm_password, $db_type1, $db_type2,$db_class);
}
}



&unpack_db_clonefile($db_version_11204);

foreach (@db_type2){

$db_type2=$_;
$db_type1=shuffle('1','2');
$db_name="q11204$db_type2";
$cmd="$OAKCLI_HOME/oakcli create database -db $db_name -version $db_version_11204";
printf "$cmd\n";

if($db_type2 eq '1'){
$ee_node=shuffle('1','2');
printf "Database type:$db_type1, Database Deployment:$db_type2, Node Number:$ee_node, Database Class:$db_class\n";
&create_db($cmd, $root_password, $sysasm_password, $db_type1, $db_type2,$db_class, $ee_node);
}else{
printf "Database type:$db_type1, Database Deployment:$db_type2, Database Class:$db_class\n";
&create_db($cmd, $root_password, $sysasm_password, $db_type1, $db_type2,$db_class);
}
}

if (defined $db_version[2]){

my $db_version_11203=$db_version[2];
print "$db_version_11203\n";

&unpack_db_clonefile($db_version_11203);
$db_type1=shuffle('1','2');
$db_type2=shuffle(@db_type2);
$db_name="q11203$db_type2";
$cmd="$OAKCLI_HOME/oakcli create database -db $db_name -version $db_version_11203";
printf "$cmd\n";
if($db_type2 eq '1'){
$ee_node=shuffle('1','2');
printf "Database type:$db_type1, Database Deployment:$db_type2, Node Number:$ee_node, Database Class:$db_class\n";
&create_db($cmd, $root_password, $sysasm_password, $db_type1, $db_type2,$db_class, $ee_node);
}else{
printf "Database type:$db_type1, Database Deployment:$db_type2, Database Class:$db_class\n";
&create_db($cmd, $root_password, $sysasm_password, $db_type1, $db_type2,$db_class);
}
}
select STDOUT;

sub unpack_db_clonefile{
my $version=$_[0];

my $cmd1;
my $cmd2;
`mkdir -p /tmp/tmp`;
if ($version ne '11.2.0.4.0'){
$version=~s/\.//g;
#printf "$version\n";
$cmd1="/usr/bin/scp 10.208.184.63:/scratch/chqin/OAKDBbundle/OAKDB${version}Bundle.zip /tmp/tmp";
$cmd2="$OAKCLI_HOME/oakcli unpack -package /tmp/tmp/OAKDB${version}Bundle.zip";
print "$cmd1\n";
}else{
$cmd1="/usr/bin/scp 10.208.184.63:/scratch/chqin/OAKDBbundle/OAKDB11204Bundle.zip /tmp/tmp";
$cmd2="$OAKCLI_HOME/oakcli unpack -package /tmp/tmp/OAKDB11204Bundle.zip";
}

my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd1) or die "cann't not spawn $cmd1\n";
my $pass=$exp->expect($timeout, 'continue connecting');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'password');
$exp->send("welcome2\r") if($pass);
$exp->interact();

my $exp2=new Expect;
my $timeout2=100;
$exp2->spawn($cmd2) or die "cann't not spawn $cmd2\n";
$pass=$exp2->expect($timeout2, 'Press');
$exp2->send("yes\r") if($pass);
$exp2->interact() if($pass);

}




sub create_db(){

my $argument_count=$#_+1;
my $cmd=$_[0];
my $root_password=$_[1];
my $sysasm_password=$_[2];
my $db_type1=$_[3];
my $db_type2=$_[4];
my $db_class=$_[5];
my $Others=2;
my $ee_node;
if ($argument_count==7){
 $ee_node=$_[6];
}
my $de;
if ($db_type1 eq '1'){
	$de=shuffle('1','2');
	}else{
	$de='1';
	}
my $yes_or_no=shuffle('Y', 'N');
my $exp=new Expect;
my $timeout=50;


$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
#my $pass=$exp->expect($timeout, -re=>qr/password\s/i);
# my $pass=$exp->expect($timeout, 'password');
# $exp->send("$root_password\r") if($pass);
# $pass=$exp->expect($timeout, 'password');
# $exp->send("$root_password\r") if($pass);
my $pass=$exp->expect($timeout, 'root');
$exp->send("$root_password\r") if($pass);
$pass=$exp->expect($timeout, 'root');
$exp->send("$root_password\r") if($pass);

$pass=$exp->expect($timeout, 'SYSASM password');
$exp->send("$sysasm_password\r") if($pass);
$pass=$exp->expect($timeout, "re-enter the 'SYSASM'");
$exp->send("$sysasm_password\r") if($pass);

$pass=$exp->expect($timeout, 'Database type');
$exp->send("$db_type1\r") if($pass);
$pass=$exp->expect($timeout, 'Database edition');
$exp->send("$de\r") if($pass);

$pass=$exp->expect($timeout, 'Database Deployment');
$exp->send("$db_type2\r") if($pass);

$pass=$exp->expect($timeout, 'Node Number');
$exp->send("$ee_node\r") if($pass);

$pass=$exp->expect($timeout, 'FLASH');
$exp->send("$yes_or_no\r") if($pass);

$pass=$exp->expect($timeout, 'Others');
$exp->send("$Others\r") if($pass);

$pass=$exp->expect($timeout, 'Database Class');
$exp->send("$db_class\r") if($pass);

$pass=$exp->expect($timeout, 'EM');
$exp->send("$yes_or_no\r") if($pass);

$pass=$exp->expect($timeout, 'ASMSNMP password');
$exp->send("welcome1\r") if($pass);
$pass=$exp->expect($timeout, "re-enter the 'ASMSNMP'");
$exp->send("welcome1\r") if($pass);

#$exp->expect(10,[
#qr/password/i,
#sub{
#$exp->send("$root_password\r\n");
#exp_continue;
#}
#],
#[
#'root',
#sub{
#$exp->send("$root_password\r\n");
#exp_continue_timeout;
#}
#]
#);
$exp->interact() 
}