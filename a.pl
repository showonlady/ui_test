#!/usr/bin/perl -w
use strict;
use warnings;

my $i,
my @i =(1..9);
my @j =(1..9);
for $i(@i){
 foreach(@j){
print '  $i*$_';
}
print "\n";


}