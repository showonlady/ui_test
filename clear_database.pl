use Getopt::Long;
use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;
my $ODACLI="/opt/oracle/dcs/bin/odacli";
my $i='$1';
my @databaseid=`$ODACLI list-databases|grep Configured|awk '{print $i}'`;
foreach(@databaseid){
printf "delete database successfully!\n" if(delete_database($_));
}
my @dbhomeid=`$ODACLI list-dbhomes|grep Configured|awk '{print $i}'`;
foreach(@dbhomeid){
printf "delete dbhome successfully!\n" if(delete_dbhome($_));
}




