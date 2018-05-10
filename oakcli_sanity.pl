#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used patch odalite database to the defined version 
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 04/19/17- Creation


use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;
my $OAKCLI="/opt/oracle/oak/bin/oakcli";
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



print "\n==================check oakcli show disk==================\n";
my @not_good_disk=`$OAKCLI show disk|grep -vi good|grep pd`;
print "warning:@not_good_disk\n" if defined ($not_good_disk[0]);
my @local_disk=`$OAKCLI show disk -local`;
print @local_disk;
if (is_bm_or_not){
	print "warning:local disks may have some errors!\n" if(!$local_disk[0]=~/sd/);
}else{
	print "warning: show local disk message error on vm!\n" if (!$local_disk[0]=~/'-local' is not supported/);
}
my @shared_disks=`$OAKCLI show disk -shared`;
my @show_disks=`$OAKCLI show disk`;
print "warning: shared disks are not working well!" unless(@shared_disks~~@show_disks);
my @disks=`$OAKCLI show disk |awk 'NR>3 {print \$1}';`;
my $disk=shuffle(@disks);
chomp $disk;
print $disk;
my $show_disk_all=`$OAKCLI show disk $disk -all`;
print "warning: oakcli show disk -all doesn't work!\n" unless(defined $show_disk_all);
my @show_disk=`$OAKCLI show disk $disk`;
my $backup_type=`egrep -i DBBackupType /opt/oracle/oak/onecmd/onecommand.params`;
my $disk_state=`$OAKCLI show disk|grep $disk |awk '{print \$4}';`;
chomp $disk_state;
my $disk_statedetails=`$OAKCLI show disk|grep $disk |awk '{print \$5}';`;
chomp $disk_statedetails;
my $flag=0;

for my $show_disk(@show_disk){
	if($show_disk=~/data:(\d+):.*reco:(\d+):.*redo/){
		if($backup_type=~/external/i){
			print "warning:show disk not work good!\n" unless($1 eq 86 && $2 eq 14);
			}elsif($backup_type=~/internal/i){
			print "warning:show disk not work good!\n" unless($1 eq 43 && $2 eq 57);
		}
	$flag=1;
	}
	if($show_disk=~/^\s+State\s*:\s*(\S+)/){
	
		print "warning: oakcli show disk shows the state not correct,$1!\n" unless($1=~/$disk_state/i);
	}
	if($show_disk=~/StateDetails\s*:\s*(\S+)/){
		print "warning: oakcli show disk shows the statedetails not correct,$1!\n" unless($1=~/$disk_statedetails/i);
	}
}

print "\n==================check oakcli show diskgroup==================\n";
my @diskgroup = `$OAKCLI show diskgroup`;
foreach (@diskgroup){
	chomp;
}
print "warning: oakcli show diskgroup doesn't work well!\n@diskgroup\n" unless('DATA'~~@diskgroup&&'RECO'~~@diskgroup&&'REDO'~~@diskgroup);
for my $diskgroup_name('DATA','RECO','REDO'){
	my @show_diskgroup=`$OAKCLI show diskgroup $diskgroup_name|grep -vi online|grep pd`;
	print "warning:@show_diskgroup\n" if defined ($show_diskgroup[0]);
}

print "\n==================check oakcli show storage==================\n";

my @showstorage_errors=`$OAKCLI show storage -errors`;
print "warning: oakcli show storage return errors!\n@showstorage_errors" if($showstorage_errors[0]=~/\S+/);

my @showstorage=`$OAKCLI show storage`;
for my $showstorage(@showstorage){
	if($showstorage=~/^\s+\/dev.+\s+(\d+)gb/){
		print "warning:disk size is 0gb, $1\n" if($1==0);
	}
}
my $controller_num=`$OAKCLI show storage|grep controller`;
$controller_num=~/:\s+(\d)/;
$controller_num=$1;
print $controller_num;
my $expander_num=`$OAKCLI show storage|grep expander`;
$expander_num=~/:\s+(\d)/;
$expander_num=$1;

print "warning:oakcli show storage could not show the number of controller or expander!\n" unless (defined $controller_num && defined $expander_num);
for my $i (0..$controller_num-1){
	my @show_controller=`oakcli show controller $i`;
	printf "warning:oakcli show controller $i doesn't work!\n" unless ($show_controller[0]=~/Controller.*information/);
}
for my $i (0..$expander_num-1){
	my @show_expander=`oakcli show expander $i`;
	printf "warning:oakcli show expander $i doesn't work!\n" unless ($show_expander[0]=~/Expander.*information/);
}

print "\n==================check oakcli show fs==================\n";





