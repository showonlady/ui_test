
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


	my $ossbkcname1=$ossbkcname.$flag;
	my $oss_options1=$oss_options.$options[0];
	die "create backup config $ossbkcname1 fail!\n" unless(create_backupconfig($ossbkcname1,$bkdest2,$oss_options1));
	$flag+=1;
    die "update database with backupconfig $ossbkcname1 fail!\n" unless(update_database("-in $dbname","-bin $ossbkcname1",$backup_password));
	

	
	
	print"===================backup database=========================\n";
    $tag1=name_generate(@dataSource, '8');
	die "backup database fail!\n" unless(create_backup("-in $dbname","$backuptype[2]","-k 10 -t $tag1"));
	print"===================recover database=========================\n";
	##date/sp/control file loss!####
	print "#####################date/sp/control file loss!###########\n";
	$pitr=&current_pitr($dbname);
	&all_file_loss($dbname);	
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr",$backup_password));
	&status_database($dbname);

	###control file loss!####
	print "#####################control file loss!###########\n";
	$pitr=&current_pitr($dbname);
	&controlfile_loss($dbname);
	die "recover database fail!\n" unless(recover_database("-in $dbname","-t PITR -r $pitr",$backup_password));
	&status_database($dbname);