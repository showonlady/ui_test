use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
our $ODACLI="/opt/oracle/dcs/bin/odacli";

my $dbname='n4';
my @output=datafile($dbname);
print @output;
delete_asm_file(@output);

sub delete_asm_file{
my @output=@_;
my $grid_owner='grid';
open delete_file, ">/home/$grid_owner/delete.sh"||die "Can't create delete_file: $!";
foreach (@output){
chomp;
print delete_file "asmcmd rm -rf $_\n";
}
close delete_file;

my $grid_group=`ls -l /home/|grep $grid_owner|awk '{print \$4}'`;
chomp $grid_group;
`/bin/chown $grid_owner:$grid_group /home/$grid_owner/delete.sh`;
`/bin/chmod +x /home/$grid_owner/delete.sh`;
#my $sql_output=`/bin/su - $grid_owner -c /home/$grid_owner/delete.sh`;
}

sub datafile{
my $dbname=shift;
my $dbhome=dbnametohome($dbname);
my $sql1="select name from v\\\$datafile";
my $rac_owner=`cat $dbhome/install/utl/rootmacro.sh | grep "^ORACLE_OWNER=" | cut -d "=" -f 2`;
chomp $rac_owner;
my $instancename=`/bin/su - $rac_owner -c "ps -ef|grep ora_pmon_$dbname|grep -v grep"`;
chomp $instancename;
my @temp_item=split /\s+/, $instancename;
my $pmon_name=$temp_item[-1];
$instancename=substr $pmon_name,9;
#print $instancename;
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
$sql_output =~ s/\s*$//;
$sql_output =~ s/^\s*//;
my @out=split /\n/,$sql_output;
return @out[2..@out-1];
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
