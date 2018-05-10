#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to check the datbase related commands, it creates the db with ramdom options according to the cpucores.
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/12/16 - Creation
# - CHQIN 10/26/17 - Modify it for X7-2
use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;

use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;



 my $sql_check_version='select BANNER from v\$version';

my $sql_version=sql_check_version('test2','/u01/app/oraclett/product/12.1.0.2/dbhome_2',$sql_check_version);
 
 
 my $dt='EE';
 
 print "sqlplus check find inconsistent!\n" unless ($sql_version=~/12.1.0.2/);
 if ($dt =~/EE/i){
	print "sqlplus check find db edition inconsistent, $sql_version!\n" if($sql_version=~/Enterprise Edition/);
	}else{
	print "sqlplus check find db edition inconsistent, $sql_version!\n" unless($sql_version=~/Standard Edition/);
	}
	

sub sql_check_version{
my $dbname=shift;
my $dbhome=shift;
my $sql=shift;
my $rac_owner=`cat $dbhome/install/utl/rootmacro.sh | grep "^ORACLE_OWNER=" | cut -d "=" -f 2`;
chomp $rac_owner;
my $instancename=`/bin/su - $rac_owner -c "ps -ef|grep ora_pmon_$dbname|grep -v grep |awk '{print \$8}'|cut -d "_" -f 3"`;
chomp $instancename;

open sql_check_file, ">/home/$rac_owner/sql_check.sh" || die "Can't create sql_check_file: $!";
print sql_check_file "#!/bin/bash\n";
print sql_check_file "export ORACLE_SID=$instancename\n";
print sql_check_file "export ORACLE_HOME=$dbhome\n";
print sql_check_file "$dbhome/bin/sqlplus -S -L / as sysdba <<EOF\n";
print sql_check_file "$sql;\n";
print sql_check_file "EOF\n";
close sql_check_file;
my $rac_group=`ls -l /home/|grep $rac_owner|awk '{print \$4}'`;
chomp $rac_group;
`/bin/chown $rac_owner:$rac_group /home/$rac_owner/sql_check.sh`;
`/bin/chmod +x /home/$rac_owner/sql_check.sh`;
my $sql_output=`/bin/su - $rac_owner -c /home/$rac_owner/sql_check.sh`;
}