#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to test backup and recovery
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/20/17 - Creation



use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;

my $testlog = 'check-backup-recovery_oss.log';

open TESTLOG, ">> $testlog" || die "Can't create logfile: $!";

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;
our $ODACLI="/opt/oracle/dcs/bin/odacli";
my $dbname=$ARGV[0];
my @dataSource = (0..9,'a'..'z','A'..'Z');
my $ossname=name_generate(@dataSource, '8');
#my $ossname='swift1';
my $bkdest1='Disk';
my $bkdest2='ObjectStore';
my $bkdest3='None';
my $ossbkcname=name_generate(@dataSource, '8');

my $oss_options="-c chqin -on $ossname ";
my @options=('-w 15','-cr -w 1','-cr -w 30','-no-cr -w 1','-no-cr -w 30');
my $flag=1;
my $backup_password="WElcome123#_";
my @backuptype=('Regular-L0','Regular-L1','Longterm');
my $tag1;
our $instancename=dbnametoinstance($dbname);


print "\n=====================OSS=============================\n";
#print "delete oss $ossname fail!\n" unless(delete_objectstoreswift("-in $ossname"));
die "create oss fail!" unless(create_objectstoreswift($ossname));

for my $op(@options){
	my $ossbkcname1=$ossbkcname.$flag;
	my $oss_options1=$oss_options.$op;
	die "create backup config $ossbkcname1 fail!\n" unless(create_backupconfig($ossbkcname1,$bkdest2,$oss_options1));
	$flag+=1;
    die "update database with backupconfig $ossbkcname1 fail!\n" unless(update_database("-in $dbname","-bin $ossbkcname1",$backup_password));
	$tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[0]","-t $tag1"));
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[1]"));
	$tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[2]","-k 10 -t $tag1"));

	print"===================recover database=========================\n";
	my $scn_sql="select current_scn SCN from v\\\$database";
	my $pitr_sql="select to_char(scn_to_timestamp(current_scn),'mm/dd/yyyy hh24:mi:ss') PITR from v\\\$database";
	my $spfile_sql="select value from v\\\$parameter where name ='spfile'";
	my $control_sql="select name from v\\\$controlfile";	
	my $datafile_sql="select name from v\\\$datafile";
	my @spfile=data_control_spfile($dbname,$spfile_sql);
	my @controlfile=data_control_spfile($dbname,$control_sql);
	my @datafile=data_control_spfile($dbname,$datafile_sql);

	####data file loss!####
	print "#####################data file loss!###########\n";
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@datafile);
		}else{
		delete_acfs_file(@datafile);
		}
		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest",$backup_password));
	#####control file loss!####
	print "#####################control file loss!###########\n";
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@controlfile);
		}else{
		delete_acfs_file(@controlfile);
		}
		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest",$backup_password));
	#####spfile file loss!####
	print "#####################spfile file loss!###########\n";
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@spfile);
		}else{
		delete_acfs_file(@spfile);
		}
		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest",$backup_password));
	
	print"===================backup database=========================\n";

	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[0]"));


	
	print"===================recover database=========================\n";
	@spfile=data_control_spfile($dbname,$spfile_sql);
	@controlfile=data_control_spfile($dbname,$control_sql);
	@datafile=data_control_spfile($dbname,$datafile_sql);

	
	####data file loss!####
	print "#####################data file loss!###########\n";
	my $control_scn=scn_pitr($dbname,$scn_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@datafile);
		}else{
		delete_acfs_file(@datafile);
		}	
	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $control_scn",$backup_password));
	#####control file loss!####
	print "#####################control file loss!###########\n";
	 $control_scn=scn_pitr($dbname,$scn_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@controlfile);
		}else{
		delete_acfs_file(@controlfile);
		}
		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $control_scn",$backup_password));
	#####spfile file loss!####
	print "#####################spfile file loss!###########\n";
	 $control_scn=scn_pitr($dbname,$scn_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@spfile);
		}else{
		delete_acfs_file(@spfile);
		}
		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $control_scn",$backup_password));
	
	print"===================backup database=========================\n";
    $tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[1]","-t $tag1"));

	print"===================recover database=========================\n";
	
	@spfile=data_control_spfile($dbname,$spfile_sql);
	@controlfile=data_control_spfile($dbname,$control_sql);
	@datafile=data_control_spfile($dbname,$datafile_sql);
	####data file loss!####
	print "#####################data file loss!###########\n";
	my $recoveryTimeStamp=scn_pitr($dbname,$pitr_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@datafile);
		}else{
		delete_acfs_file(@datafile);
		}	
	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $recoveryTimeStamp",$backup_password));
	#####control file loss!####
	print "#####################control file loss!###########\n";
	$recoveryTimeStamp=scn_pitr($dbname,$pitr_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@controlfile);
		}else{
		delete_acfs_file(@controlfile);
		}
		
	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $recoveryTimeStamp",$backup_password));
	#####spfile file loss!####
	print "#####################spfile file loss!###########\n";
	$recoveryTimeStamp=scn_pitr($dbname,$pitr_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@spfile);
		}else{
		delete_acfs_file(@spfile);
		}
		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $recoveryTimeStamp",$backup_password));
	
	###control/sp file  loss!####
	# print "#####################control/sp file loss!###########\n";
	# $recoveryTimeStamp=scn_pitr($dbname,$pitr_sql);
	# @spfile=data_control_spfile($dbname,$spfile_sql);
	# @controlfile=data_control_spfile($dbname,$control_sql);
	
	# if(db_on_asm_or_acfs($dbname)){
		# delete_asm_file(@controlfile,@spfile);
		# }else{
		# delete_acfs_file(@controlfile,@spfile);
		# }	
	# die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $recoveryTimeStamp",$backup_password));
	
	
	print"===================backup database=========================\n";
    $tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[1]","-t $tag1"));

	print"===================recover database=========================\n";
	@spfile=data_control_spfile($dbname,$spfile_sql);
	@controlfile=data_control_spfile($dbname,$control_sql);
	@datafile=data_control_spfile($dbname,$datafile_sql);

	####data/control/sp file  loss!####
	print "#####################data/control/sp file loss!###########\n";
	$recoveryTimeStamp=scn_pitr($dbname,$pitr_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@datafile,@controlfile,@spfile);
		}else{
		delete_acfs_file(@datafile,@controlfile,@spfile);
		}	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $recoveryTimeStamp",$backup_password));
	#####control file loss!####
	print "#####################control file loss!###########\n";
	 $control_scn=scn_pitr($dbname,$scn_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@controlfile);
		}else{
		delete_acfs_file(@controlfile);
		}
		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $control_scn",$backup_password));
	#####spfile file loss!####
	print "#####################spfile file loss!###########\n";
	 $control_scn=scn_pitr($dbname,$scn_sql);
	if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@spfile);
		}else{
		delete_acfs_file(@spfile);
		}
		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $control_scn",$backup_password));
	
		
	}

	


	
sub delete_asm_file{
my @output=@_;
my $grid_owner=`ls -l /u01/app/12.2*|awk '{print \$9}';`;
chomp $grid_owner;
$grid_owner=~s/^\s*//;
$grid_owner=~s/\s*$//;
open delete_file, ">/home/$grid_owner/delete.sh"||die "Can't create delete_file: $!";
foreach (@output){
$_ =~ s/^\s*//;
	if($_=~/^\+/){
	chomp;
	print "$_\n";
	print delete_file "asmcmd rm -rf $_\n";
	}
}
close delete_file;

my $grid_group=`ls -l /home/|grep $grid_owner|awk '{print \$4}'`;
chomp $grid_group;
`/bin/chown $grid_owner:$grid_group /home/$grid_owner/delete.sh`;
`/bin/chmod +x /home/$grid_owner/delete.sh`;

sql_result($dbname,"shutdown immediate");
`/bin/su - $grid_owner -c /home/$grid_owner/delete.sh`;
sql_result($dbname,"startup");
}
 
 
sub delete_acfs_file{
my @output=@_;
foreach (@output){
$_ =~ s/^\s*//;
	if($_=~/^\//){
	chomp;
	print "$_\n";
	`rm -rf $_`;
	}
}
sql_result($dbname,"startup force");
}  

  
sub scn_pitr{
my $dbname=shift;
my $sql1=shift;
my $sql_output=sql_result($dbname,$sql1);
$sql_output =~ s/\s*$//;
my @out=split /\n/,$sql_output;
chomp $out[-1];
$out[-1] =~ s/^\s*//;
return $out[-1]
}

sub data_control_spfile{
my $dbname=shift;
my $sql1=shift;
my $sql_output=sql_result($dbname,$sql1);
$sql_output =~ s/\s*$//;
$sql_output =~ s/^\s*//;
my @out=split /\n/,$sql_output;
my @re1=@out[2..@out-1];
@re1=@out[2..@out-3] if($out[-1]=~/rows selected/i);
return @re1;
}

  
sub dbnametohome{
my $dbname=shift;
my $dbhomeidout=`$ODACLI describe-database -in $dbname|grep -i "Home ID";`;
my @dbhomeid=split (/:\s*/,$dbhomeidout);
my $homeid=$dbhomeid[1];
chomp $homeid;
my $homeloc=`$ODACLI describe-dbhome -i $homeid |grep -i "Home Location"`;
my @dbhomeloc=split (/:\s*/,$homeloc);
my $home=$dbhomeloc[1];
chomp $home;
return $home;
}

sub dbnametoinstance{
my $dbname=shift;
my $dbhome=dbnametohome($dbname);
my $rac_owner=`cat $dbhome/install/utl/rootmacro.sh | grep "^ORACLE_OWNER=" | cut -d "=" -f 2`;
chomp $rac_owner;
my $instancename=`/bin/su - $rac_owner -c "ps -ef|grep ora_pmon_$dbname|grep -v grep"`;
chomp $instancename;
my @temp_item=split /\s+/, $instancename;
my $pmon_name=$temp_item[-1];
$instancename=substr $pmon_name,9;
}


sub db_on_asm_or_acfs{
my $dbname=shift;
my $dbstorage=`$ODACLI describe-database -in $dbname|grep -i storage`;
if($dbstorage =~ /ASM/i){
	return 1;
	}else{
	return 0;
	}
}

sub sql_result{
my $dbname=shift;
my $dbhome=dbnametohome($dbname);
my $sql1=shift;
my $rac_owner=`cat $dbhome/install/utl/rootmacro.sh | grep "^ORACLE_OWNER=" | cut -d "=" -f 2`;
chomp $rac_owner;
open datafile_check_file, ">/home/$rac_owner/sql_check.sh" || die "Can't create datafile_check_file: $!";
print datafile_check_file "#!/bin/bash\n";
print datafile_check_file "export ORACLE_SID=$instancename\n";
print datafile_check_file "export ORACLE_HOME=$dbhome\n";
print datafile_check_file "$dbhome/bin/sqlplus -S -L / as sysdba <<EOF\n";
print datafile_check_file "$sql1;\n";
print datafile_check_file "EOF\n";
close datafile_check_file;
my $rac_group=`ls -l /home/|grep $rac_owner|awk '{print \$4}'`;
chomp $rac_group;
`/bin/chown $rac_owner:$rac_group /home/$rac_owner/sql_check.sh`;
`/bin/chmod +x /home/$rac_owner/sql_check.sh`;
my $sql_output=`/bin/su - $rac_owner -c /home/$rac_owner/sql_check.sh`;
}