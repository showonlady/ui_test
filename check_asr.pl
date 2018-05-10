use strict ;
use warnings ;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use bmiaaslib;
my $testlog = 'check-asr-odalite.log';

open TESTLOG, "> $testlog" || die "Can't create logfile: $!";

select TESTLOG;
$|=1;

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;

&delete_asr||die "fail to delete the asr!\n" if(&describe_asr);
my %ilom_setting=&check_ilom_rules_setting;
printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/1/);
my @options;
my $proxyport="-t 80";
my $proxyserver="-r 148.87.19.20";
my $user='asr-qa_ca@oracle.com';
my $user_password="!Asrdts2011";
my @snmp_version=shuffle('v2', 'v3');
my $snmp_version='v2';
my $external_ip="10.210.80.10";
my %describe_asr;

printf "========= Test configure internal ASR=========\n\n";
push @options,$proxyport;
push @options,$proxyserver;
push @options,"-u $user";
push @options, "-ha $user_password";
if(shuffle(0..1)){
push @options, "-e internal";
}
if(shuffle(0..1)){
$snmp_version=$snmp_version[0];
push @options, "-s $snmp_version";
}
my $option=join ' ',@options;
if(configure_asr($option)){
die "describe asr failed!\n" unless(&describe_asr);
%describe_asr=&describe_asr;
printf "describe asr successfully!\n" if($describe_asr{"ASR Type"}=~/Internal/i && $describe_asr{"UserName"}=~/$user/ && $describe_asr{"SnmpVersion"}=~/$snmp_version/i);
########################add the ilom setting check###############################
%ilom_setting=&check_ilom_rules_setting;
  if($snmp_version eq 'v2'){
     printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/2/ && $ilom_setting{'destination_port'}=~/162/ && $ilom_setting{'community_or_username'}=~/public/);
  }elsif($snmp_version eq 'v3'){
     printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/3/ && $ilom_setting{'destination_port'}=~/162/ && $ilom_setting{'community_or_username'}=~/odasnmpv3user/);
  }
my @assets=`/opt/asrmanager/bin/asr list_asset`;
printf "@assets\n";
my $i='$1';
my $y='$2';
my $z='$3';
my $time=`date "+%Y%m%d%H%M%S"`;
die "test asr failed!\n" unless(&test_asr);
sleep 120;
my $log_time=`stat /var/opt/asrmanager/log/asr.log |grep Modify|awk -F '.' '{print $i}'|awk '{print $y$z}'|awk -F '-' '{print $i$y$z}'|awk -F ':' '{print $i$y$z}'`;
die "asr log failed to update!\n" if($time gt $log_time);
}


printf "========= Test update internal ASR=========\n\n";
my @update_options;
push @update_options,$proxyport;
push @update_options,$proxyserver;
push @update_options,"-u $user";
push @update_options, "-ha $user_password";
if(shuffle(0..1)){
push @update_options, "-e internal";
}
push @update_options, "-s $snmp_version[1]";
my $update_option=join ' ',@update_options;
if(update_asr($update_option)){
die "describe asr failed!\n" unless(&describe_asr);
%describe_asr=&describe_asr;
printf "describe asr successfully!\n" if($describe_asr{"ASR Type"}=~/Internal/i && $describe_asr{"UserName"}=~/$user/ && $describe_asr{"SnmpVersion"}=~/$snmp_version[1]/i);
########################add the ilom setting check###############################
%ilom_setting=&check_ilom_rules_setting;
  if($snmp_version[1] eq 'v2'){
     printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/2/ && $ilom_setting{'destination_port'}=~/162/ && $ilom_setting{'community_or_username'}=~/public/);
  }elsif($snmp_version[1] eq 'v3'){
     printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/3/ && $ilom_setting{'destination_port'}=~/162/ && $ilom_setting{'community_or_username'}=~/odasnmpv3user/);
  }
my @assets=`/opt/asrmanager/bin/asr list_asset`;
printf "@assets\n";
my $i='$1';
my $y='$2';
my $z='$3';
my $time=`date "+%Y%m%d%H%M%S"`;
die "test asr failed!\n" unless(&test_asr);
sleep 120;
my $log_time=`stat /var/opt/asrmanager/log/asr.log |grep Modify|awk -F '.' '{print $i}'|awk '{print $y$z}'|awk -F '-' '{print $i$y$z}'|awk -F ':' '{print $i$y$z}'`;
die "asr log failed to update!\n" if($time gt $log_time);
} 

printf "========= Test configure external ASR=========\n\n";

&delete_asr||die "fail to delete the asr!\n" if(&describe_asr);
my $external_option="-e external";
$external_option=$external_option." -i $external_ip";
$external_option=$external_option." -s $snmp_version[0]";
if(configure_asr($external_option)){
die "describe asr failed!\n" unless(&describe_asr);
%describe_asr=&describe_asr;
printf "describe asr successfully!\n" if($describe_asr{"ASR Type"}=~/External/i && $describe_asr{"External ASR Manager IP"}=~/$external_ip/ && $describe_asr{"SnmpVersion"}=~/$snmp_version[0]/i);
#######################add the ilom setting check###############################
%ilom_setting=&check_ilom_rules_setting;
  if($snmp_version[0] eq 'v2'){
     printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/2/ && $ilom_setting{'destination_port'}=~/162/ && $ilom_setting{'destination'}=~/$external_ip/ && $ilom_setting{'community_or_username'}=~/public/);
  }elsif($snmp_version[0] eq 'v3'){
     printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/3/ && $ilom_setting{'destination_port'}=~/162/ && $ilom_setting{'destination'}=~/$external_ip/ && $ilom_setting{'community_or_username'}=~/odasnmpv3user/);
  }
my @active_asset_script=`cat /tmp/activateExternalAssets.pl`;
printf "@active_asset_script\n";
die "test asr failed!\n" unless(&test_asr);
}

printf "========= Test update external ASR=========\n\n";
my $update_external_option="-e external"." -i $external_ip"." -s $snmp_version[1]";
if(update_asr($update_external_option)){
die "describe asr failed!\n" unless(&describe_asr);
%describe_asr=&describe_asr;
printf "describe asr successfully!\n" if($describe_asr{"ASR Type"}=~/External/i && $describe_asr{"External ASR Manager IP"}=~/$external_ip/ && $describe_asr{"SnmpVersion"}=~/$snmp_version[1]/i);
#######################add the ilom setting check###############################
%ilom_setting=&check_ilom_rules_setting;
  if($snmp_version[1] eq 'v2'){
     printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/2/ && $ilom_setting{'destination_port'}=~/162/ && $ilom_setting{'destination'}=~/$external_ip/ && $ilom_setting{'community_or_username'}=~/public/);
  }elsif($snmp_version[1] eq 'v3'){
     printf "ilom rules is not setting correctly!\n" unless($ilom_setting{'snmp_version'}=~/3/ && $ilom_setting{'destination_port'}=~/162/ && $ilom_setting{'destination'}=~/$external_ip/ && $ilom_setting{'community_or_username'}=~/odasnmpv3user/);
  }
my @active_asset_script=`cat /tmp/activateExternalAssets.pl`;
printf "@active_asset_script\n";
die "test asr failed!\n" unless(&test_asr);
}








sub check_ilom_rules_setting{
my %hash;
my @cmd=`ipmitool sunoem cli "ls /SP/alertmgmt/rules/1/"`;
if(defined $cmd[0]){
  for my $line(@cmd){
    if($line=~/=/){
      $line=~s/^\s*//;
       my @tem=split /\s*=\s*/, $line;
       $hash{$tem[0]}=$tem[1];
        }
   }
}else{
die "ipmitool doesn't work!";
}
return %hash;
}

close TESTLOG;
