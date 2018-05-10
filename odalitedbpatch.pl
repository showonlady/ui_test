#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used patch odalite database to the defined version 
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 02/08/17 - Creation


use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use File::Basename;

die "please give the version, i.e.12.1.2.9.0!\n" unless(defined $ARGV[0]);
my $version=$ARGV[0];
my @dbhome_id=` /opt/oracle/dcs/bin/odacli list-dbhomes|grep -i Configured|awk '{print \$1}'`;
pop @dbhome_id unless $dbhome_id[-1]=~/\S+/;
foreach (@dbhome_id){
	chomp;
	die "update_dbhome failed!\n" unless(update_dbhome($_, $version));
   }
   
