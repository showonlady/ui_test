#!/usr/bin/perl -w

use bmiaaslib;

my $testlog = 'check-cpucore-odalite.log';

open TESTLOG, "> $testlog" || die "Can't create logfile: $!";

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;

print "========= Negative Test=========\n\n";

my @corenumber = (-1,0,1,3,38,35);

for my $num (@corenumber) {
  print "\nChange cpucore to $num\n";
  update_cpucore($num);
}

print "========= Positive Test=========\n\n";

my $orgcore = describe_cpucore;
if($orgcore > 2){
my @opt=('2', '-f');
printf "update cpucore to 2 forcely!\n" if(update_cpucore(@opt) && &lscpu_output==2);
}

@corenumber = (4,6,8,10,12,14,16,18,20,18,16,14);

for my $num (@corenumber) {
  print "\nChange cpucore to $num\n";
  if(update_cpucore($num)){
  my $lscpu_online_cpu=&lscpu_output;
  printf "update cpucore successfuly!\n" if($lscpu_online_cpu == $num);
  }

}

@opt=($orgcore, '-f');
printf "update cpucore to the original forcelly!\n" if(update_cpucore(@opt) && &lscpu_output==$orgcore);

sub lscpu_output{
my $socket=`lscpu|grep Socket`;
my $cores_per_socket=`lscpu|grep Core`;
$socket=(split /:\s*/, $socket)[1];
$cores_per_socket=(split /:\s*/, $cores_per_socket)[1];
chomp $socket;
chomp $cores_per_socket;
my $online_cpu=$socket * $cores_per_socket;
return $online_cpu;
}






close TESTLOG;

