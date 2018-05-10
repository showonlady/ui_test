#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to check the dbhome related commands
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/14/16 - Creation



use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;

my $testlog = 'check-dbhome-odalite.log';

open TESTLOG, ">> $testlog" || die "Can't create logfile: $!";

#select TESTLOG;
#$|=1;

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;



print "========= Create dbhome=========\n\n";

my @dataSource = (0..9,'a'..'z','A'..'Z');
my $dbname=name_generate(@dataSource, '8');
my @listdbhome;
my $dbhome_version=shuffle(keys %version_dbclone);
scp_unpack_dbclone($version_dbclone{$dbhome_version}) if(!is_clone_exist($dbhome_version));

if(create_dbhome($dbhome_version)){
      @listdbhome=&list_dbhomes;
      if ($listdbhome[2]=~/$dbhome_version/ && $listdbhome[4]=~ /Configured/){
      print "list/describe dbhome failed!\n" if (!@listdbhome ~~ describe_dbhome($listdbhome[0]));
        if(shuffle(0..1)){ if(update_dbhome($listdbhome[0])){
                          printf "update dbhome successfully!\n" ;
                          }else{
                          die "update dbhome failed!\n";
                          }
         }
      if(create_database($dbname, 'welcome123', "-dh $listdbhome[0]")){
      my @result = list_databases();
      print "Create Database successfully\n" if ($result[1] =~ /$dbname/ && $result[7] =~ /Configured/);
      my %temp = describe_database($result[0]);
      print "describe database failed!\n" if($temp{'Home ID'} ne $listdbhome[0]);
      if(shuffle(0..1)){ if(update_dbhome($listdbhome[0])){
                          printf "update dbhome successfully!\n" ;
                          }else{
                          die "update dbhome failed!\n";
                          }    
                       }
      die "Delete database failed!\n" unless (delete_database($result[0]));
      die "Delete dbhome failed!\n"  unless (delete_dbhome$listdbhome[0]);

      }else{
      print "create databases failed!\n";
      }
}else{
printf "create dbhome failed!\n";
}
}

close TESTLOG;

