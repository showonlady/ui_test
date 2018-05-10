#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to do the sanity check for the ODA
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/27/16 - Creation
use strict;
use warnings;
use Expect;

my $kernel_version_12_1_2_10="2.6.39-400.290.1.el6uek.x86_64";
my $OAKCLI="/opt/oracle/oak/bin/oakcli";
my @xenrpm_12_1_2_10=qw/ netxen-firmware-4.0.590-0.1.el5 xen-4.1.3-25.el5.223.36 xen-devel-4.1.3-25.el5.223.36 xenpvboot-0.1-8.el5 xen-tools-4.1.3-25.el5.223.36/;

###for the upgraded env, return 1, else will return 0.
sub is_upgrade_or_not{
my $latest_version="12.1.2.10";
my $System_dir=`ls /opt/oracle/oak/pkgrepos/System/|grep -v $latest_version`;
#print "$System_dir\n";
if($System_dir=~/12.1.2/){
	return 1;
	}else{
	return 0;
	}

}
sub login_server{

my $hostname=shift;
my $password=shift;
my $run_cmd=shift;
my $cmd="ssh -l root $hostname $run_cmd";

my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
my $pass=$exp->expect($timeout, '(yes/no)');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'password');
$exp->send("$password\r") if($pass);
$exp->interact() if($pass);
}
####Check the env is bm or vm, bm:1 vm:0 exception:-1
sub is_bm_or_not{
my @env_hw=`$OAKCLI show env_hw`;
if(defined($env_hw[0])){
    if($env_hw[0]=~/BM/i){
	return 1;
	}elsif($env_hw[0]=~/VM/i){
	return 0;
	}else{
	die "warning: oakcli show env_hw doesn't work well!\n";
		}
}else{
	die "warning: oakcli show env_hw doesn't work!\n";
		}
}
sub is_ib_or_not{

`/sbin/lspci | grep -qi Mellanox`;
	if(!$?){
		return 1;
		}else{
		return 0
		}
}

sub is_V4{
my $output=`cat /proc/cmdline`;
	if($output=~/TYPE=V4/){
	return 1;
	}else{
	return 0;
	}
}
sub is_X6{
my $output=`cat /proc/cmdline`;
	if($output=~/TYPE=X6/){
	return 1;
	}else{
	return 0;
	}
}
    


print "\n==================check the TFA status==================\n";
system("tfactl print status");
print "\n==================check OAKD status==================\n";
system("ps -ef|grep oakd|grep -v grep");
my $i='$9';
my @oakd_process=`ps -ef|grep oakd|grep -v grep|awk '{print $i}'`;
print "ERROR: oakd process is not running normally!\n" if(@oakd_process ne 1 ||(!$oakd_process[0]=~/foreground/i));
print "\n==================check boot size==================\n";
system("df -h /boot");
$i='$2';
my $boot_size=` df -h /boot|awk 'NR>1 {print $i}'`;
print "WARNING: boot size is not 485M" unless($boot_size=~/485/);
print "\n==================check core dump==================\n";
my @grid_core=`/usr/bin/find /opt /root /u01/app/grid /u01/app/1*/grid/log -name core.*`;
my @oracle_core=`/usr/bin/find /u01/app/oracle -name core.* ! -name core.min.js ! -name core.js ! -name core.jar ! -name core.def`;
my @db_alert=`/bin/egrep 'ORA-600|ORA-00600|ORA-07445' /u01/app/oracle/diag/rdbms/*/*/trace/alert_*.log`;
my @asm_alert=`/bin/egrep 'ORA-600|ORA-00600|ORA-07445' /u01/app/grid/diag/asm/*/*/trace/alert_*.log`;
if(defined $grid_core[0]){
print "WARNING: core dump found!\n";
foreach(@grid_core){
print `ls -l $_`; 
}
}
if(defined $oracle_core[0]){
print "WARNING: core dump found!\n";
foreach(@oracle_core){
print `ls -l $_`; 
}
}
if(defined $db_alert[0]){
print "WARNING: core dump found!\n";
print "@db_alert\n";
}
if(defined $asm_alert[0]){
print "WARNING: core dump found!\n";
print "@asm_alert\n";
}
print "\n==================check kernel version==================\n";
my $kernel_version=`uname -r`;
chomp $kernel_version;
print "$kernel_version\n";
print "WARNING: kernel version is not correct!\n" if($kernel_version ne $kernel_version_12_1_2_10);
print "\n==================check IB env are using RDS==================\n";
my $skgxpinfo=`/u01/app/12.1.0.2/grid/bin/skgxpinfo -v`;
chomp $skgxpinfo;
print "$skgxpinfo\n";
`/sbin/lspci | grep -qi Mellanox`;
if(!$?){
print "WARNING: IB env is not using RDS\n" unless($skgxpinfo=~/RDS/i);
}else{
print "WARNING: NON-IB env is not using UDP\n" unless($skgxpinfo=~/UDP/i);
}
print "\n==================check parameter max_disk_count==================\n";
$i='$3';
my $max_disk_count=`grep -i 'attr max_disk_count' /opt/oracle/extapi/asmappl.config |awk '{print $i}'`;
chomp $max_disk_count;
print "$max_disk_count\n";
print "WARNING: max_disk_count is not 100" if($max_disk_count ne 100);

if(!&is_upgrade_or_not){
	print "\n==================check the os image logs in the fresh env==================\n";
	if(is_bm_or_not){
		my @image_error=`egrep -i 'error|fail' post-ks-*|egrep -v 'overruns|ubuntu'`;
		if(!$?){
		print "WARNING: some errors found in the image log!\n";
		print "@image_error\n";
		}
	}else{
		&login_server("192.168.16.24", "welcome1", 'cat post-ks*|egrep -i "error|fail"|egrep -v "overrun|History">postlog_error');
		my @args=stat("postlog_error");
		if($args[7]){
		print "WARNING: some errors found in the log!\n";
		print `cat postlog_error`;
		}
	}
}
		

if(&is_bm_or_not eq 0){
print "\n==================check dom0 xen rpm==================\n";
&login_server("192.168.16.24", "welcome1", "rpm -qa|grep xen|sort>xenrpm_info");
my @xenrpm_info=`cat xenrpm_info`;
foreach(@xenrpm_info){
	chomp;
	}
print "WARNING: XEN rpms are not correct!\n@xenrpm_info\n" unless(@xenrpm_info~~@xenrpm_12_1_2_10);
	
}elsif(&is_bm_or_not eq 1){
	print "this is a bm env!\n";
	}
print "\n==================check parameter in sysctl.conf==================\n";
##Bug18896566
my $result=`cat /etc/sysctl.conf|grep net.ipv4.conf.all.rp_filter`;
print "$result\n";
print "WARNING: net.ipv4.conf.all.rp_filter is not set to 2!\n" unless($result=~/2/);
##Bug16887511
$result=`cat /etc/sysctl.conf|grep net.core.rmem_max`;
print "$result\n";
print "WARNING: net.core.rmem_max is missing!\n" if($?);
$result=`cat /etc/sysctl.conf|grep net.core.wmem_max`;
print "$result\n";
print "WARNING: net.core.wmem_max is missing!\n" if($?);
print "\n==================check ntp status==================\n";
my $ntp_setting=`egrep -i NTP_SERVER /opt/oracle/oak/onecmd/onecommand.params`;
print "$ntp_setting\n";
if($ntp_setting=~/(\d.*\d)/){
	print "NTP is set:$1\n";
	my $ntp_status=`service ntpd status`;
	print "WARNING: service ntpd status is not correct!\n" unless($ntp_status=~/running/);
	my $i='$4';
	my $j='$5';
	my $x='$6';
	my $y='$7';
	my $chkconfig_ntp=`chkconfig --list|grep ntp|awk '{print $i$j$x$y}'`;
	print "WARNING: chkconfig --list ntp is not correct!\n" if($chkconfig_ntp=~/off/);
	my $ctss_mode=`/u01/app/12.1.0.2/grid/bin/crsctl check ctss`;
	print "WARNING: ctss is not in Observer mode\n" unless($ctss_mode=~/Observer/i);
	}else{
	print "NTP is not set!\n";
	my $ntp_status=`service ntpd status`;
	print "WARNING: service ntpd status is not correct!\n" unless($ntp_status=~/stop/);
	my $i='$4';
	my $j='$5';
	my $x='$6';
	my $y='$7';
	my $chkconfig_ntp=`chkconfig --list|grep ntp|awk '{print $i$j$x$y}'`;
	print "WARNING: chkconfig --list ntp is not correct!\n" if($chkconfig_ntp=~/on/);
	my $ctss_mode=`/u01/app/12.1.0.2/grid/bin/crsctl check ctss`;
	print "WARNING: ctss is not in Active mode\n" unless($ctss_mode=~/Active/i);
	}
print "\n==================check backup type==================\n";
$i='$3';
my $j='$2';
my $disk_name=`oakcli show disk |grep e0_pd_03|awk '{print $j}'`;
chomp $disk_name;
print `parted $disk_name print`;
my @partition=`parted $disk_name print|grep primary|awk '{print $i}'`;
if(@partition ne 2){
	print "WARNING: parted list error!\n";
	}else{
	foreach(@partition){
		chomp;
		}
	map {s/GB//i} @partition;	
	my $result=int($partition[0]/$partition[1]*100+0.5);
	my $backup_type=`egrep -i DBBackupType /opt/oracle/oak/onecmd/onecommand.params`;
	print "$backup_type\n";
	if($backup_type=~/external/i){
		print "WARNING: DATA partion is not set to 86 for external,$result!\n" unless($result eq 86);
		}elsif($backup_type=~/internal/i){
		print "WARNING: DATA partion is not set to 43 for internal,$result!\n" unless($result eq 43);
	}
}	

print "\n==================check network setting===============\n";
my $ib_bonding_opts='BONDING_OPTS="mode=active-backup miimon=250 use_carrier=1 updelay=500 downdelay=500 primary=ib0"';
my $bond0_bonding_opts='mode=active-backup miimon=100 primary=eth';

if(&is_ib_or_not){
		my $ib0_mtu=`cat /etc/sysconfig/network-scripts/ifcfg-ib0|grep -i mtu`;
		my $ib1_mtu=`cat /etc/sysconfig/network-scripts/ifcfg-ib1|grep -i mtu`;
		my $ibbond0_mtu=`cat /etc/sysconfig/network-scripts/ifcfg-ibbond0|grep -i mtu`;
		print "WARNING:ib0/ib1/ibbond0 mtu setting is not correct!\n" unless($ib0_mtu=~/7000/ && $ib0_mtu=~/7000/ && $ibbond0_mtu=~/7000/);
		my $bonding_opts=`cat /etc/sysconfig/network-scripts/ifcfg-ibbond0|grep -i BONDING_OPTS`;
		chomp $bonding_opts;
		print "WARNING: BONDING_opts is not setting correctly!\n" unless($bonding_opts eq $ib_bonding_opts);
		my $ib0_type=`cat /etc/sysconfig/network-scripts/ifcfg-ib0|grep -i type`;
		my $ib1_type=`cat /etc/sysconfig/network-scripts/ifcfg-ib1|grep -i type`;
		my $ibbond0_type=`cat /etc/sysconfig/network-scripts/ifcfg-ibbond0|grep -i type`;
		print "WARNING:ib0/ib1/ibbond0 type setting is not correct!\n" unless($ib0_type=~/Infiniband/ && $ib0_type=~/Infiniband/ && $ibbond0_type=~/Infiniband/);
		}
if(&is_bm_or_not){
	my $bond0_type=`cat /etc/sysconfig/network-scripts/ifcfg-bond0|grep -i type`;
	my $bond1_type=`cat /etc/sysconfig/network-scripts/ifcfg-bond1|grep -i type`;
	print "WARNING:bond0/bond1 type setting is not correct!\n" unless($bond0_type=~/BOND/ && $bond1_type=~/BOND/);
	my $bond0_opts=`cat /etc/sysconfig/network-scripts/ifcfg-bond0|grep BONDING_OPTS`;
	chomp $bond0_opts;
	print "WARNING: bond0 BONDING_OPTS is not setting correctly!\n" unless($bond0_opts=~/$bond0_bonding_opts/);
	if(&is_ib_or_not){
		print `cat /etc/sysconfig/network-scripts/ifcfg-ib0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-ib1`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth1`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth2`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth3`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-ibbond0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-bond0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-bond1`;
		my @offload_opts=`cat /etc/sysconfig/network-scripts/ifcfg-eth*|grep ETHTOOL_OFFLOAD_OPTS`;
		print "WARNING: ETHTOOL_OFFLOAD_OPTS is not set correctly!\n" if(@offload_opts ne 4);
		foreach(@offload_opts){
			print "WARNING: ETHTOOL_OFFLOAD_OPTS is not set correctly!" unless(/"lro off"/);
			}
		my @ethernet_type=`cat /etc/sysconfig/network-scripts/ifcfg-eth*|grep -i type`;
		print "WARNING: ETHERNET type is not set correctly!\n" if(@ethernet_type ne 4);
		foreach(@ethernet_type){
			print "WARNING: ETHERNET is not set correctly!" unless(/ethernet/i);
			}
				
		}else{
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth1`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth2`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth3`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth4`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth5`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-bond0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-bond1`;
		my $eth0_mtu=`cat /etc/sysconfig/network-scripts/ifcfg-eth0|grep -i mtu`;
		my $eth1_mtu=`cat /etc/sysconfig/network-scripts/ifcfg-eth1|grep -i mtu`;
		print "WARNING: eth0/eth1 mtu setting is not set to 9000 in non-ib env!\n" unless($eth0_mtu=~/9000/ && $eth1_mtu=~/9000/);
		
		my @offload_opts=`cat /etc/sysconfig/network-scripts/ifcfg-eth*|grep ETHTOOL_OFFLOAD_OPTS`;
		print "WARNING: ETHTOOL_OFFLOAD_OPTS is not set correctly!\n" if(@offload_opts ne 6);
		foreach(@offload_opts){
			print "WARNING: ETHTOOL_OFFLOAD_OPTS is not set correctly!" unless(/"lro off"/);
			}
		my @ethernet_type=`cat /etc/sysconfig/network-scripts/ifcfg-eth*|grep -i type`;
		print "WARNING: ETHERNET type is not set correctly!\n" if(@ethernet_type ne 6);
		foreach(@ethernet_type){
			print "WARNING: ETHERNET is not set correctly!" unless(/ethernet/i);
			}
		}
}else{
	if(&is_ib_or_not){
		print `cat /etc/sysconfig/network-scripts/ifcfg-ib0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-ib1`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth1`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-ibbond0`;
		`cat /etc/sysconfig/network-scripts/ifcfg-eth0|grep -i mtu`;
		print "WARNING: mtu should not be set to eth0 in ib env!\n" unless($?);
		`cat /etc/sysconfig/network-scripts/ifcfg-eth1|grep -i mtu`;
		print "WARNING: mtu should not be set to eth1 in ib env!\n" unless($?);
		my @ethernet_type=`cat /etc/sysconfig/network-scripts/ifcfg-eth*|grep -i type`;
		print "WARNING: ETHERNET type is not set correctly!\n" if(@ethernet_type ne 2);
		foreach(@ethernet_type){
			print "WARNING: ETHERNET is not set correctly!" unless(/ethernet/i);
			}
		}else{
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth0`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth1`;
		print `cat /etc/sysconfig/network-scripts/ifcfg-eth2`;
		my @ethernet_type=`cat /etc/sysconfig/network-scripts/ifcfg-eth*|grep -i type`;
		print "WARNING: ETHERNET type is not set correctly!\n" if(@ethernet_type ne 3);
		foreach(@ethernet_type){
			print "WARNING: ETHERNET is not set correctly!" unless(/ethernet/i);
			}
		`cat /etc/sysconfig/network-scripts/ifcfg-eth1|grep -i mtu`;
		print "WARNING: mtu should not be set to eth1 in non-ib env!\n" unless($?);
		`cat /etc/sysconfig/network-scripts/ifcfg-eth2|grep -i mtu`;
		print "WARNING: mtu should not be set to eth2 in non-ib env!\n" unless($?);
		my $eth0_mtu=`cat /etc/sysconfig/network-scripts/ifcfg-eth0|grep -i mtu`;
		print "WARNING: eth0 mtu setting is not set to 9000 in non-ib env!\n" unless($eth0_mtu=~/9000/);
		}
}
print "\n==================check asm attrubutes setting===============\n";
my $compatible;
my $griduser=`cat /opt/oracle/oak/onecmd/onecommand.params|egrep "CRSUSR="`;
chomp $griduser;
$griduser=(split /=/, $griduser)[1];

if(&is_V4 || &is_X6){
	$compatible="12.1.0.2";
	}else{
	$compatible="11.2.0.2";
	}
	
my @asm_data=`su - $griduser -c "asmcmd lsattr -G data -lm"`;
print @asm_data;
foreach(@asm_data){
	if(/appliance.name/){
		print "WARNING: appliance.name is not correct for DATA!\n" unless($_=~/ODA/i);
		}elsif(/compatible.advm/){
		print "WARNING: compatible.advm is not correct for DATA!\n" unless($_=~/12.1.0.2/);
		}elsif(/compatible.asm/){
		print "WARNING: compatible.asm is not correct for DATA!\n" unless($_=~/12.1.0.2/);
		}elsif(/compatible.rdbms/){
		print "WARNING: compatible.rdbms is not correct for DATA!\n" unless($_=~/$compatible/);
		}elsif(/content.type/){
		print "WARNING: content.type is not correct for DATA!\n" unless($_=~/data/i);
		}
	}
my @asm_reco=`su - $griduser -c "asmcmd lsattr -G reco -lm"`;
print @asm_reco;
foreach(@asm_reco){
	if(/appliance.name/){
		print "WARNING: appliance.name is not correct for RECO!\n" unless($_=~/ODA/i);
		}elsif(/compatible.advm/){
		print "WARNING: compatible.advm is not correct for RECO!\n" unless($_=~/12.1.0.2/);
		}elsif(/compatible.asm/){
		print "WARNING: compatible.asm is not correct for RECO!\n" unless($_=~/12.1.0.2/);
		}elsif(/compatible.rdbms/){
		print "WARNING: compatible.rdbms is not correct for RECO!\n" unless($_=~/$compatible/);
		}elsif(/content.type/){
		print "WARNING: content.type is not correct for RECO!\n" unless($_=~/recovery/i);
		}
	}
my @asm_redo=`su - $griduser -c "asmcmd lsattr -G redo -lm"`;
print @asm_redo;
foreach(@asm_redo){
	if(/appliance.name/){
		print "WARNING: appliance.name is not correct for REDO!\n" unless($_=~/ODA/i);
		}elsif(/compatible.advm/){
		print "WARNING: compatible.advm is not correct for REDO!\n" unless($_=~/12.1.0.2/);
		}elsif(/compatible.asm/){
		print "WARNING: compatible.asm is not correct for REDO!\n" unless($_=~/12.1.0.2/);
		}elsif(/compatible.rdbms/){
		print "WARNING: compatible.rdbms is not correct for REDO!\n" unless($_=~/$compatible/);
		}elsif(/content.type/){
		print "WARNING: content.type is not correct for REDO!\n" unless($_=~/redo/i);
		}
	}
if(&is_V4){
	my @asm_flash=`su - $griduser -c "asmcmd lsattr -G flash -lm"`;
	print @asm_flash;
	foreach(@asm_flash){
	if(/appliance.name/){
		print "WARNING: appliance.name is not correct for flash!\n" unless($_=~/ODA/i);
		}elsif(/compatible.advm/){
		print "WARNING: compatible.advm is not correct for flash!\n" unless($_=~/12.1.0.2/);
		}elsif(/compatible.asm/){
		print "WARNING: compatible.asm is not correct for flash!\n" unless($_=~/12.1.0.2/);
		}elsif(/compatible.rdbms/){
		print "WARNING: compatible.rdbms is not correct for flash!\n" unless($_=~/$compatible/);
		}
	}
}

my $asm_comp=`cat /opt/oracle/extapi/asmappl.config |grep asm_compatibility`;
print "WARNING: asm_compatibility is not correct!\n" unless($asm_comp=~/12.1.0.2/);
my $rdbms_comp=`cat /opt/oracle/extapi/asmappl.config |grep rdbms_compatibility`;
print "WARNING: rdbms_compatibility is not correct!\n" unless($rdbms_comp=~/$compatible/);








