use strict ;
use warnings ;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use bmiaaslib;
my $testlog = 'check-swift.log';

open TESTLOG, "> $testlog" || die "Can't create logfile: $!";

select TESTLOG;
$|=1;

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;
my $endpointurl="-e https://swiftobjectstorage.us-phoenix-1.oraclecloud.com/v1";
my $tenantname="-t dbaasimage";
my $username="-u chunling.qin@oracle.com";
my $password1="wgT.ZM&>U6Tmm#F]O&9n";
my $password2="aJ!(E2E1Hy[2V&}vYcwg";
my $swiftname="swiftst1";
my $create_objectstoreswift_option=$endpointurl.$tenantname;
$create_objectstoreswift_option=$create_objectstoreswift_option.$username;
$create_objectstoreswift_option=$create_objectstoreswift_option."-hp $password1";
$create_objectstoreswift_option=$create_objectstoreswift_option."-n $swiftname";
