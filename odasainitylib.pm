#===========================================================================================
#
#   NAME: odasanitylib.pm
#
#   DESCRIPTION: Function Lib for ODA sanity check_netsec
#
#   NOTE:
#
#   Modify
#
#        170419    chqin   Created
#        
#If you find any bug or have any question, please send email to chunling.qin@oracle.com
#===========================================================================================
#


use strict;
package odasanitylib;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
                 is_bm_or_not
                 
);

use File::Spec::Functions;
use File::Path;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use Expect;
use warnings ;
use English;

my $ODACLI = "/opt/oracle/dcs/bin/odacli";

####Check the env is bm or vm, bm:1 vm:0 exception:-1
sub is_bm_or_not{
my @env_hw=`$OAKCLI show env_hw`;
if(defined($env_hw[0])){
    if($env_hw[0]=~/BM/i){
	return 1;
	}elsif($env_hw[0]=~/VM/i){
	return 0;
	}else{
	die "warning: oakcli show env_hw doesn't work well!\n";
		}
}else{
	die "warning: oakcli show env_hw doesn't work!\n";
		}
}

