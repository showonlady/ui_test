
use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;
my @temp;

#&need_scp("12.1.0.2.171017");
#printf "create 12.1.0.2 dbhome successfully!\n" if(create_dbhome("12.1.0.2.171017"));
#@temp=&list_dbhomes;
#my $dbhome_id=shift @temp;
my $dbhome_id="3f515294-1733-4070-9711-d6f82c8b8628";
my $db_password="WElcome12_#";

&need_scp("11.2.0.4.171017");
#print "create 11.2.0.4.171017 db successfully!\n" if(create_database("new1", $db_password, "-v 11.2.0.4.171017 -r acfs"));
@temp=&list_databases;
my $database_id=shift @temp;
#print "upgrade a new 11.2 db to the new created dbhome successfully!\n" if(upgrade_database($database_id,$dbhome_id));

#print "upgrade a old patched 11.2 db to the new created dbhome successfully!\n" if(upgrade_database("7df221ab-fb9e-40fb-865b-49147be3e439",$dbhome_id));

&need_scp("11.2.0.4.170814");
#print "create 11.2.0.4.170814 db successfully!\n" if(create_database("new2", $db_password, "-v 11.2.0.4.170814 -r acfs"));
@temp=&list_databases;
$database_id=shift @temp;
print "upgrade a new lower 11.2 db to the new created dbhome successfully!\n" if(upgrade_database($database_id,$dbhome_id));



sub need_scp{
my $db_11=shift;
my $db_11_key;

if($db_11=~/11.2.0.4.170814/ || $db_11=~/12.1.0.2.170814/){
$db_11_key=$db_11.'_x6';
}else{
$db_11_key=$db_11;
}
scp_unpack_dbclone($version_dbclone{$db_11_key}) if(!is_clone_exist($db_11));
}