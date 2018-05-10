#
#===========================================================================================
#
#   NAME: bmiaaslib.pm
#
#   DESCRIPTION: Function Lib for backup and recovery
#
#   NOTE:
#
#   Modify
#
#        180109    Chqin   Created
#If you find any bug or have any question, please send email to chunling.qin@oracle.com
#===========================================================================================
#


use strict;
package back_recover_lib;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
                 current_scn
				 current_pitr
				 datafile_loss
				 controlfile_loss
				 spfile_loss
				 sp_controlfile_loss
				 control_datafile_loss
				 all_file_loss
				 dbnametohome
				 dbnametoinstance
				 stop_database
				 start_database
				 status_database
);

use File::Spec::Functions;
use File::Path;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use Expect;
use warnings ;
use English;

our $ODACLI = "/opt/oracle/dcs/bin/odacli";
	
	
sub current_scn{
my $dbname=shift;
my $scn_sql="select current_scn SCN from v\\\$database";
my $control_scn=scn_pitr($dbname,$scn_sql);
}

sub current_pitr{
my $dbname=shift;
my $pitr_sql="select to_char(scn_to_timestamp(current_scn),'mm/dd/yyyy hh24:mi:ss') PITR from v\\\$database";
my $recoveryTimeStamp=scn_pitr($dbname,$pitr_sql);
}

 
sub datafile_loss{
my $dbname=shift;
my $datafile_sql="select name from v\\\$datafile";
my @datafile=data_control_spfile($dbname,$datafile_sql);
if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@datafile);
		}else{
		delete_acfs_file(@datafile);
		}
}

sub controlfile_loss{
my $dbname=shift;
my $control_sql="select name from v\\\$controlfile";	
my @controlfile=data_control_spfile($dbname,$control_sql);
if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@controlfile);
		}else{
		delete_acfs_file(@controlfile);
		}
}

sub spfile_loss{
my $dbname=shift;
my $spfile_sql="select value from v\\\$parameter where name ='spfile'";
my @spfile=data_control_spfile($dbname,$spfile_sql);
if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@spfile);
		}else{
		delete_acfs_file(@spfile);
		}
}

sub sp_controlfile_loss{
my $dbname=shift;
my $spfile_sql="select value from v\\\$parameter where name ='spfile'";
my $control_sql="select name from v\\\$controlfile";	
my @spfile=data_control_spfile($dbname,$spfile_sql);
my @controlfile=data_control_spfile($dbname,$control_sql);
if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@controlfile,@spfile);
		}else{
		delete_acfs_file(@controlfile,@spfile);
		}	

}

sub control_datafile_loss{
my $dbname=shift;
my $control_sql="select name from v\\\$controlfile";	
my $datafile_sql="select name from v\\\$datafile";
my @controlfile=data_control_spfile($dbname,$control_sql);
my @datafile=data_control_spfile($dbname,$datafile_sql);
if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@datafile,@controlfile);
		}else{
		delete_acfs_file(@datafile,@controlfile);
		}	

}
sub all_file_loss{
my $dbname=shift;
my $spfile_sql="select value from v\\\$parameter where name ='spfile'";
my $control_sql="select name from v\\\$controlfile";	
my $datafile_sql="select name from v\\\$datafile";
my @spfile=data_control_spfile($dbname,$spfile_sql);
my @controlfile=data_control_spfile($dbname,$control_sql);
my @datafile=data_control_spfile($dbname,$datafile_sql);
if(db_on_asm_or_acfs($dbname)){
		delete_asm_file(@datafile,@controlfile,@spfile);
		}else{
		delete_acfs_file(@datafile,@controlfile,@spfile);
		}	
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
&stop_database;
`/bin/su - $grid_owner -c /home/$grid_owner/delete.sh`;
&start_database;
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
&start_database;
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
if($instancename){
	chomp $instancename;
	my @temp_item=split /\s+/, $instancename;
	my $pmon_name=$temp_item[-1];
	$instancename=substr $pmon_name,9;
	return $instancename;
	}else{
	die "No db instance!\n";
	}
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
my $instancename=dbnametoinstance($dbname);
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

sub stop_database{
my $dbname=$ARGV[0];
my $dbhome=dbnametohome($dbname);
my $rac_owner=`cat $dbhome/install/utl/rootmacro.sh | grep "^ORACLE_OWNER=" | cut -d "=" -f 2`;
chomp $rac_owner;
open datafile_check_file, ">/home/$rac_owner/stop_database.sh" || die "Can't create datafile_check_file: $!";
print datafile_check_file "#!/bin/bash\n";
print datafile_check_file "export ORACLE_HOME=$dbhome\n";
print datafile_check_file "$dbhome/bin/srvctl stop database -d $dbname;\n";
close datafile_check_file;
my $rac_group=`ls -l /home/|grep $rac_owner|awk '{print \$4}'`;
chomp $rac_group;
`/bin/chown $rac_owner:$rac_group /home/$rac_owner/stop_database.sh`;
`/bin/chmod +x /home/$rac_owner/stop_database.sh`;
my $sql_output=`/bin/su - $rac_owner -c /home/$rac_owner/stop_database.sh`;

}

sub start_database{
my $dbname=$ARGV[0];
my $dbhome=dbnametohome($dbname);
my $rac_owner=`cat $dbhome/install/utl/rootmacro.sh | grep "^ORACLE_OWNER=" | cut -d "=" -f 2`;
chomp $rac_owner;
open datafile_check_file, ">/home/$rac_owner/start_database.sh" || die "Can't create datafile_check_file: $!";
print datafile_check_file "#!/bin/bash\n";
print datafile_check_file "export ORACLE_HOME=$dbhome\n";
print datafile_check_file "$dbhome/bin/srvctl start database -d $dbname;\n";
close datafile_check_file;
my $rac_group=`ls -l /home/|grep $rac_owner|awk '{print \$4}'`;
chomp $rac_group;
`/bin/chown $rac_owner:$rac_group /home/$rac_owner/start_database.sh`;
`/bin/chmod +x /home/$rac_owner/start_database.sh`;
my $sql_output=`/bin/su - $rac_owner -c /home/$rac_owner/start_database.sh`;
}

sub status_database{
my $dbname=$ARGV[0];
my $dbhome=dbnametohome($dbname);
my $rac_owner=`cat $dbhome/install/utl/rootmacro.sh | grep "^ORACLE_OWNER=" | cut -d "=" -f 2`;
chomp $rac_owner;
open datafile_check_file, ">/home/$rac_owner/status_database.sh" || die "Can't create datafile_check_file: $!";
print datafile_check_file "#!/bin/bash\n";
print datafile_check_file "export ORACLE_HOME=$dbhome\n";
print datafile_check_file "$dbhome/bin/srvctl status database -d $dbname;\n";
close datafile_check_file;
my $rac_group=`ls -l /home/|grep $rac_owner|awk '{print \$4}'`;
chomp $rac_group;
`/bin/chown $rac_owner:$rac_group /home/$rac_owner/status_database.sh`;
`/bin/chmod +x /home/$rac_owner/status_database.sh`;
my $sql_output=`/bin/su - $rac_owner -c /home/$rac_owner/status_database.sh`;
print "\n$sql_output\n";
}

