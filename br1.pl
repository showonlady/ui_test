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
use back_recover_lib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;

my $testlog = 'check-backup-recovery.log';

open TESTLOG, ">> $testlog" || die "Can't create logfile: $!";

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;
our $ODACLI="/opt/oracle/dcs/bin/odacli";
our $dbname=$ARGV[0];
die "please give the db name!" unless(defined $dbname);
my @dataSource = (0..9,'a'..'z','A'..'Z');
my $ossname=name_generate(@dataSource, '8');
my $bkdest1='Disk';
my $bkdest2='ObjectStore';
my $bkdest3='None';
my $ossbkcname=name_generate(@dataSource, '8');
my $oss_options="-c chqin -on $ossname ";
my @options=('-w 15','-cr -w 1','-cr -w 30','-no-cr -w 1','-no-cr -w 30');
my $flag=1;
my $flag2=1;
my $backup_password="WElcome123#_";
my @backuptype=('Regular-L0','Regular-L1','Longterm');
my $tag1;
#our $instancename=dbnametoinstance($dbname);
my $pitr;
my $scn;


my $diskbkcname=name_generate(@dataSource, '8');
my @options2=('-w 7','-cr -w 1','-cr -w 14','-no-cr -w 1','-no-cr -w 14');
my @backuptype2=('Regular-L0','Regular-L1');


print "\n=====================OSS=============================\n";
#print "delete oss $ossname fail!\n" unless(delete_objectstoreswift("-in $ossname"));
die "create oss fail!" unless(create_objectstoreswift($ossname));

for my $op(@options){   
	my $ossbkcname1=$ossbkcname.$flag;
	my $oss_options1=$oss_options.$op;
	die "create backup config $ossbkcname1 fail!\n" unless(create_backupconfig($ossbkcname1,$bkdest2,$oss_options1));
	$flag+=1;
    die "update database with backupconfig $ossbkcname1 fail!\n" unless(update_database("-in $dbname","-bin $ossbkcname1",$backup_password));
	
	print"===================backup database=========================\n";
	$tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[0]","-t $tag1"));
	# die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[1]"));
	# $tag1=name_generate(@dataSource, '8');
	# die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[2]","-k 10 -t $tag1"));

	print"===================recover database=========================\n";
	#data file loss!####
	print "#####################data file loss!###########\n";
	&datafile_loss($dbname);		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest",$backup_password));
	&status_database;
	#control file loss!####
	print "#####################control file loss!###########\n";
	&controlfile_loss($dbname);		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest",$backup_password));
	&status_database;

	#spfile file loss!####
	print "#####################spfile file loss!###########\n";
	&spfile_loss($dbname);
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest",$backup_password));
	&status_database;
	
	# ####control/sp file  loss!####
	# print "#####################control/sp file loss!###########\n";
	# &sp_controlfile_loss;
	# die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest",$backup_password));
		
	print"===================backup database=========================\n";
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[1]"));
	print"===================recover database=========================\n";
	##data/control file loss!####
	print "#####################data/control file loss!###########\n";
	$scn=&current_scn($dbname);
	&control_datafile_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $scn",$backup_password));
	&status_database;

	##control file loss!####
	print "#####################control file loss!###########\n";
	$scn=&current_scn($dbname);
	&controlfile_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $scn",$backup_password));
	&status_database;

	#spfile file loss!####
	print "#####################spfile file loss!###########\n";
	$scn=&current_scn($dbname);
	&spfile_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $scn",$backup_password));
	&status_database;

	# #####control/sp file  loss!####
	# print "#####################control/sp file loss!###########\n";
	# $scn=&current_scn($dbname);
	# &sp_controlfile_loss($dbname);
	# die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -r $scn",$backup_password));
	
	print"===================backup database=========================\n";
    $tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[2]","-k 10 -t $tag1"));
	print"===================recover database=========================\n";
	##date/sp/control file loss!####
	print "#####################date/sp/control file loss!###########\n";
	$pitr=&current_pitr($dbname);
	&all_file_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr",$backup_password));
	&status_database;

	###control file loss!####
	print "#####################control file loss!###########\n";
	$pitr=&current_pitr($dbname);
	&controlfile_loss($dbname);
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr",$backup_password));
	&status_database;

	###spfile file loss!####
	print "#####################spfile file loss!###########\n";
	$pitr=&current_pitr($dbname);
	&spfile_loss($dbname);		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr",$backup_password));
	&status_database;

	# #####control/sp file  loss!####
	# print "#####################control/sp file loss!###########\n";
	# $pitr=&current_pitr($dbname);
	# &sp_controlfile_loss($dbname);
	# die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr",$backup_password));
	
}	
	
for my $op(@options2){
	my $diskbkcname1=$diskbkcname.$flag2;
	die "create backup config fail!\n" unless(create_backupconfig($diskbkcname1,$bkdest1,$op));
	$flag2+=1;
    die "update database with backupconfig $diskbkcname1 fail!\n" unless(update_database("-in $dbname","-bin $diskbkcname1"));
	print"===================backup database=========================\n";
	$tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[0]","-t $tag1"));
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[1]"));

	print"===================recover database=========================\n";
	#data file loss!####
	print "#####################data file loss!###########\n";
	&datafile_loss($dbname);		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest"));
	&status_database;

	#control file loss!####
	print "#####################control file loss!###########\n";
	&controlfile_loss($dbname);		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest"));
	&status_database;

	#spfile file loss!####
	print "#####################spfile file loss!###########\n";
	&spfile_loss($dbname);
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest"));
	&status_database;

	# ####control/sp file  loss!####
	# print "#####################control/sp file loss!###########\n";
	# &sp_controlfile_loss($dbname);
	# die "recover database fail!\n" unless(recover_database("-in $dbname","-t Latest"));
		
	print"===================backup database=========================\n";
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[0]"));
	print"===================recover database=========================\n";
	##data/control file loss!####
	print "#####################data/control file loss!###########\n";
	$scn=&current_scn($dbname);
	&control_datafile_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $scn"));
	&status_database;

	##control file loss!####
	print "#####################control file loss!###########\n";
	$scn=&current_scn($dbname);
	&controlfile_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $scn"));
	&status_database;

	#spfile file loss!####
	print "#####################spfile file loss!###########\n";
	$scn=&current_scn($dbname);
	&spfile_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $scn"));
	&status_database;

	# #####control/sp file  loss!####
	# print "#####################control/sp file loss!###########\n";
	# $scn=&current_scn($dbname);
	# &sp_controlfile_loss($dbname);
	# die "recover database fail!\n" unless(recover_database("-in $dbname","-t scn -s $scn"));
	
	print"===================backup database=========================\n";
    $tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[1]","-t $tag1"));
	print"===================recover database=========================\n";
	##data/sp/control file loss!####
	print "#####################date/sp/control file loss!###########\n";
	$pitr=&current_pitr($dbname);
	&all_file_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr"));
	&status_database;

	###control file loss!####
	print "#####################control file loss!###########\n";
	$pitr=&current_pitr($dbname);
	&controlfile_loss($dbname);
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr"));
	&status_database;

	###spfile file loss!####
	print "#####################spfile file loss!###########\n";
	$pitr=&current_pitr($dbname);
	&spfile_loss($dbname);		
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr"));
	&status_database;

	# #####control/sp file  loss!####
	# print "#####################control/sp file loss!###########\n";
	# $pitr=&current_pitr($dbname);
	# &sp_controlfile_loss($dbname);
	# die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr"));
}


	

