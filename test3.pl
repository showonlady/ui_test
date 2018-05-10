
use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;


&need_scp("12.2.0.1.171017");
#printf "create 12.2.0.1 dbhome successfully!\n" if(create_dbhome("12.2.0.1.171017"));
my @temp=&list_dbhomes;
my $dbhome_id="85a9991d-b33c-44fe-bf23-5f4dc54798bd";
my $db_password="WElcome12_#";

&need_scp("11.2.0.4.171017");
#print "create 11.2.0.4.171017 db successfully!\n" if(create_database("new1", $db_password, "-v 11.2.0.4.171017 -r acfs"));
@temp=&list_databases;
my $database_id=shift @temp;
#print "upgrade a new 11.2 db to the new created dbhome successfully!\n" if(upgrade_database($database_id,$dbhome_id));

#print "upgrade a old existing 12.1 db to the new created dbhome successfully!\n" if(upgrade_database("f0f731e6-3d69-4313-b173-e4d8ed29aef4",$dbhome_id));

&need_scp("11.2.0.4.170814");
print "create 11.2.0.4.170814 db successfully!\n" if(create_database("new1122", $db_password, "-v 11.2.0.4.170814 -r acfs"));
@temp=&list_databases;
$database_id=shift @temp;
print "upgrade a new lower 11.2 db to the new created dbhome successfully!\n" if(upgrade_database($database_id,$dbhome_id));

#print "upgrade a new 11.2 db to 12.1 dbhome successfully!\n" if(upgrade_database("225e719a-2e0b-4625-a63f-81434be8edf3","d36643d7-7eaf-4dcd-ae00-2fb32910aa02"));
#print "upgrade an upgraded 12.1 db to the new created dbhome successfully!\n" if(upgrade_database("225e719a-2e0b-4625-a63f-81434be8edf3",$dbhome_id));


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