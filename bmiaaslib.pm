#
#===========================================================================================
#
#   NAME: bmiaaslib.pm
#
#   DESCRIPTION: Function Lib for BMIaaS Test
#
#   NOTE:
#
#   Modify
#
#        161008    xuwang   Created
#        161212    chqin    modify the describe_database and create_database
#        161213    chqin    add update_reposity
#        161214    chqin    add update_dbhome
#        161217    chqin    add create_appliance
#        161219    chqin    add describe_appliance
#        161221    chqin    add asr related commands
#
#If you find any bug or have any question, please send email to xu.wang@oracle.com
#===========================================================================================
#


use strict;
package bmiaaslib;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
                 create_backup
                 describe_backupconfig 
                 list_backupconfigs
                 create_backupconfig
                 update_backupconfig
                 delete_backupconfig
                 create_backupreport
                 delete_backupreport
                 describe_backupreport
                 list_backupreports
                 list_cpucores
                 describe_cpucore
                 update_cpucore
                 create_dbstorage
                 delete_dbstorage
                 describe_dbstorage
                 list_dbstorages
                 create_dbhome
                 delete_dbhome
                 list_dbhomes
                 describe_dbhome
                 describe_netsec
                 update_netsec
                 check_netsec
                 list_schedules
                 describe_schedule
                 update_schedule
                 update_tdekey
                 create_database
                 delete_database
                 describe_database
                 list_databases
                 update_database
                 update_repository
                 update_dbhome
				 upgrade_database
                 create_appliance
                 describe_appliance
				 update_server		
                 update_dcsagent				 
                 describe_asr
                 delete_asr
                 configure_asr
				 create_objectstoreswift
				 list_objectstoreswifts
				 update_objectstoreswift
				 describe_objectstoreswift
				 delete_objectstoreswift
				 recover_database
                 update_asr
                 test_asr
                 scp_unpack_dbclone
                 name_generate
                 is_clone_exist
                 %version_dbclone
                 $latest_ver
				 scp_file
);

use File::Spec::Functions;
use File::Path;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;
use Expect;
use warnings ;
use English;

our $latest_ver="12.1.0.2.171017";
our %version_dbclone=("12.1.0.2.170117"=>"oda-sm-12.1.2.10.0-170205-DB-12.1.0.2.zip",
"12.1.0.2.161018"=>"oda-sm-12.1.2.9.0-161116-DB-12.1.0.2.zip",
"12.1.0.2.160719"=>"oda-sm-12.1.2.8.0-160809-DB-12.1.0.2.zip",
"12.1.0.2.160419"=>"oda-sm-12.1.2.7.0-160601-DB-12.1.0.2.zip",
"11.2.0.4.161018"=>"oda-sm-12.1.2.9.0-161007-DB-11.2.0.4.zip",
"11.2.0.4.160719"=>"oda-sm-12.1.2.8.0-160817-DB-11.2.0.4.zip",
"11.2.0.4.160419"=>"oda-sm-12.1.2.7.0-160601-DB-11.2.0.4.zip",
"12.1.0.2.170418"=>"oda-sm-12.1.2.11.0-170503-DB-12.1.0.2.zip",
"11.2.0.4.170418"=>"oda-sm-12.1.2.11.0-170503-DB-11.2.0.4.zip",
"11.2.0.4.170814"=>"oda-sm-12.2.1.1.0-171026-DB-11.2.0.4.zip",
"12.1.0.2.170814"=>"oda-sm-12.2.1.1.0-171026-DB-12.1.0.2.zip",
"12.2.0.1.170814"=>"oda-sm-12.2.1.1.0-171025-DB-12.2.1.1.zip",
"11.2.0.4.170814_x6"=>"oda-sm-12.1.2.12.0-170905-DB-11.2.0.4.zip",
"12.1.0.2.170814_x6"=>"oda-sm-12.1.2.12.0-170905-DB-12.1.0.2.zip",
"11.2.0.4.171017"=>"oda-sm-12.2.1.2.0-171124-DB-11.2.0.4.zip",
"12.1.0.2.171017"=>"oda-sm-12.2.1.2.0-171124-DB-12.1.0.2.zip",
"12.2.0.1.171017"=>"oda-sm-12.2.1.2.0-171124-DB-12.2.0.1.zip",
"11.2.0.4.180116"=>"odacli-dcs-12.2.1.3.0-180315-DB-11.2.0.4.zip",
"12.1.0.2.180116"=>"odacli-dcs-12.2.1.3.0-180320-DB-12.1.0.2.zip",
"12.2.0.1.180116"=>"odacli-dcs-12.2.1.3.0-180418-DB-12.2.0.1.zip",
);




my $ODACLI = "/opt/oracle/dcs/bin/odacli";



#
#  function: list_backupconfigs
#  input:    name
#  output:   id, name, recovery_window, destination
#

sub list_backupconfigs {
  my $bkcname = shift;
  my @config = ();

  my $cmd = "$ODACLI list-backupconfigs";
  my @result = `$cmd`;
 
  die "There is no backupconfig\n"  if(!defined $result[0]); 
 
  for my $line (@result) {
   if($line =~ /$bkcname/) {
   chomp $line;
   my @ret = split /\s+/, $line;
   return @ret;
   }
  }
}

#
#  function: describe_backupconfig
#  input:    id
#  output:   id, name, recovery_window, destination, nfs_backup_location
#
sub describe_backupconfig{
printf "please give the backupconfig name/id!\n" if (!defined $_[0]);
my $cmd="$ODACLI describe-backupconfig $_[0] ";
my @result=`$cmd`;
my %hash;

if (defined $result[0]){
for my $line (@result) {
     chomp $line;
     if($line=~/:/){
     $line=~s/^\s*//;
     my @value=split(/:\s*/, $line);
     $hash{$value[0]}=$value[1];
     }
}
}else{
    die "backupconfig describe fail!\n";
     }
return %hash;
}     

#
#  function: create_backupconfig
#  input:    name, recovery_window, destination
#  output:   success - 1/failure - 0
#


sub create_backupconfig {
  my $bkcname = shift;
  my $dest = shift;
  my $options = shift;
 
  die "The backup config name and destination are needed\n" unless (defined $dest && defined $bkcname ); 

  my $cmd = "$ODACLI create-backupconfig -d $dest -n $bkcname -j $options ";
  return run_job($cmd);
}

#
#  function: delete_backupconfig
#  input:    id
#  output:   success - 1/failure - 0
#


sub delete_backupconfig {
  my $id = shift;

  die "The backupconfig id/name is needed\n" unless defined $id;  

  my $cmd = "$ODACLI delete-backupconfig -j $id";
  return run_job($cmd);
}

#
#  function: update_backupconfig
#  input:    id, param(dest,loc,win)=value
#  output:   success - 1/failure - 0
#

sub update_backupconfig {
  my $id = shift;
  my $param = shift;

  die "The backupconfig id and some parameter are needed\n" unless (defined $id && defined $param); 

  if($param =~ /nfs/i) {
    return 0 unless $param =~ /loc/i;
  }

  my $cmd = "$ODACLI update-backupconfig -i $id"; 

  my @pairs = split /,/, $param;

  for my $pair (@pairs) {
    my @values = split /=/, $pair;
    $cmd = $cmd . " -d $values[1] " if($values[0] =~ /dest/i);
    $cmd = $cmd . " -l $values[1] " if($values[0] =~ /loc/i);    
    $cmd = $cmd . " -w $values[1] " if($values[0] =~ /win/i); 
  }

  return run_job($cmd);
}

#
#  function: list_backupreports(list the last backup report)
#  input:    none
#  output:   id, type(summary/detailed), dbid
#

sub list_backupreports {

  my $cmd = "$ODACLI list-backupreports";

  my @result = `$cmd`;

  die "There is no backup report\n"  if(!defined $result[0]); 

  my $line = $result[-1];
  chomp $line;
  my @tmp = split /\s+/, $line;

  my @config = @tmp[0 .. 2];

  return @config; 

}

#
#  function: describe_backupreport
#  input:    report id
#  output:   id, type(summary/detailed), report_location,dbid
#

sub describe_backupreport {

  my $id = shift;

  die "The report id is needed\n" unless (defined $id);

  my $cmd = "$ODACLI describe-backupreport -i $id";

  my @result = `$cmd`;

  die "There is no backup report\n"  if(!defined $result[0]); 

  my @ret;

  for my $line (@result) {
    chomp $line;
    my @tmp = split /: /, $line;
    if(defined $tmp[1]) {
       chomp $tmp[1];
       push @ret, $tmp[1];
    }
  }
  return @ret[0 .. 3];
}


#
#  function: create_backupreport
#  input:    dbid, type(summary/detailed, optional)
#  output:   success - 1 /failure - 0 (it will check whether the report file is existent)
#

sub create_backupreport {
   my $dbid = shift;
   my $type = shift;

   die "The database id is needed\n" unless (defined $dbid);
   $type = 'summary' unless defined $type;

   my $cmd = "$ODACLI create-backupreport -i $dbid -w $type";

   my $return = run_job($cmd);

   if($return) {
      my @report = list_backupreports;
      my $report_id = $report[0];
      @report = describe_backupreport($report[0]);
      return 0 if($report[1] ne $type);
      return 0 if($report[3] ne $dbid);
      return $report_id if(-e $report[2]);
   }

   return 0;
}

#
#  function: delete_backupreport
#  input:    report_id
#  output:   success - 1 /failure - 0 (it will check whether the report file is deleted)
#

sub delete_backupreport {
  my $id = shift;

  die "The backup report id is needed\n" unless defined $id;

  my $cmd = "$ODACLI delete-backupreport -i $id";

  my @report = describe_backupreport($id);

  my $ret = run_job($cmd);

  if($ret) {
     return 0 if (-e $report[2]);
  }
  return 1;
}

#
#  function: list_cpucores
#  input:    none
#  output:   core number, Status (Only list the last line) 
#

sub list_cpucores {
  my $cmd = "$ODACLI list-cpucores";
  my @result = `$cmd`;

  die "There is no backupconfig\n"  if(!defined $result[0]);
  
  my @items = split /\s+/, $result[-1];

  return($items[1],$items[-1]); 
}


#
#  function: describe_cpucore
#  input:    none
#  output:   core number
#

sub describe_cpucore {
  my $cmd = "$ODACLI describe-cpucore";
  my @result = `$cmd`;

  die "describe_cpucore failed!\n"  if(!defined $result[0]);
 
  chomp $result[-1]; 
  my @items = split /\s+/, $result[-1];

  return($items[1]); 
}

#
#  function: update_cpucore
#  input:    cpucore number
#  output:   success - 1/Failure - 0 (It will check the process number)
#

sub update_cpucore {
  my $count = shift;
  my $flag  = shift;
  my $cmd;
  die "The cpu count is needed!\n"  unless defined $count;
  if(defined $flag){
  $cmd = "$ODACLI update-cpucore -c $count $flag";
  }else{
  $cmd = "$ODACLI update-cpucore -c $count";
  }
  if(run_job($cmd)) {
    my $result = describe_cpucore;
    if($result==$count) {
      my $number = `cat /proc/cpuinfo | grep processor | wc -l`;
      chomp $number;
      $number=$number/2;
      return 1 if ($number == $count);
    }
  }
  return 0;
}

#
#  function: create_backup
#  input:    database_id/name,backup type, options
#  output:   success - 1/Failure - 0
#

sub create_backup {
  my $dbid = shift;
  my $backup_type=shift;
  my $options =shift;
  
  die "The dbid is needed!\n"  unless (defined $dbid && defined $backup_type);

  my $cmd = "$ODACLI create-backup -j $dbid -bt $backup_type";
  $cmd = "$ODACLI create-backup -j $dbid -bt $backup_type $options" if (defined $options);
  return run_job($cmd);
}

#
#  function: create_dbstorage
#  input:    size, dbname, type(ACFS/ASM), db_uniquename
#  output:   success - 1/Failure - 0 
#

sub create_dbstorage {
 my $size = shift;
 my $dbname = shift;
 my $type = shift;
 my $dbuname = shift;
 
 die "The db name and storage size are needed!\n"  unless defined $dbname && defined $size;

 my $cmd = "$ODACLI create-dbstorage -s $size "; 
 if (defined $dbuname) {
   $cmd = $cmd . "-u $dbuname ";
 }
 else {
   $dbuname = $dbname;
 }
 $cmd = $cmd . "-n $dbname ";
 if(defined $type) {
  $type =~ tr/a-z/A-Z/;
  $cmd = $cmd . "-r $type" if ($type eq 'ACFS' || $type eq 'ASM');
 }
 else {
  $type = 'ACFS';
 }

 if(run_job($cmd) && $type eq 'ACFS') {
   my $dir = catdir(rootdir(), 'u02', 'app', 'oracle', 'oradata', $dbuname);
   my @result = `df -h $dir`;

   for my $line (@result) {
      chomp $line;
      if($line =~ /$dbname/) {
          return 0 unless ($line =~ /dat$dbname/);
      }
      if($line =~ /$dir/) {
        if($line =~ /^\s+(\d+)/) {
           my $tmpsize = $1;
           return 1 if($tmpsize == $size);
        }
      }
   }
 }
 return 0;
}

#
#  function: delete_dbstorage
#  input:    dbstorage_id
#  output:   success - 1/Failure - 0 
#

sub delete_dbstorage {
  my $dbsid = shift;

  die "The storage id is needed!\n"  unless defined $dbsid;

  my $cmd = "$ODACLI delete-dbstorage -i $dbsid";
  return run_job($cmd);
}

#
#  function: describe_dbstorage
#  input:    dbstorage_id
#  output:   id, dbname, dbuname, type(ASM/ACFS), DATA Location, RECO Location, REDO Location, State
#

sub describe_dbstorage {
  my $dbsid = shift;

  die "The storage id is needed!\n"  unless defined $dbsid;

  my $cmd = "$ODACLI describe-dbstorage -i $dbsid";
  my @result = `$cmd`;
  die "There is no this dbstorage\n" unless defined $result[0];
  my @ret;
  for my $line (@result) {
    $line =~ s/\s+//g;
    my @item = split /:/, $line;
    push @ret, $item[1] if(defined $item[1]);
  }
  return @ret[0 .. 7];
}

#
#  function: list_dbstorages
#  input:    dbuname
#  output:   id, type(ASM/ACFS), dbuname, State
#

sub list_dbstorages {
   my $dbuname = shift;

   my $cmd = "$ODACLI list-dbstorages";

   my @result = `$cmd`;

   die "There is no dbstorage\n"  if(!defined $result[0]);
   for my $line (@result) {
    if($line =~ /$dbuname/) { 
     chomp $line;
     my @ret = split /\s+/, $line;
     return @ret;
     }
   }
}

#
#  function: list_dbhomes(List the last line)
#  input:    none
#  output:   id, name, version, location, status
#

sub list_dbhomes {

 my $cmd = "$ODACLI list-dbhomes";

 my @result = `$cmd`;

   die "There is no db homes\n"  if(!defined $result[0]);
   my $line= $result[-1];
   chomp $line;
   $line = $result[-2] unless $line =~ /\S+/;
   my @ret = split /\s+\s+/, $line;
   return @ret;
}

#
#  function: describe_dbhome
#  input:    dbhome_id
#  output:   id, name, version, location,status
#

sub describe_dbhome {
  my $dbhid = shift;

  die "The dbhome id is needed!\n"  unless defined $dbhid;

  my $cmd = "$ODACLI describe-dbhome -i $dbhid";
  my @result = `$cmd`;
  die "There is no this dbhome\n" unless defined $result[0];
  my @ret;
  for my $line (@result) {
    chomp $line;
    my @item = split /:\s+/, $line;
    push @ret, $item[1] if(defined $item[1]);
  }
  return @ret[0 .. 4]; 
}

#
#  function: delete_dbhome
#  input:    dbhome_id
#  output:   success - 1/Failure - 0
#

sub delete_dbhome {
  my $dbhid = shift;

  die "The dbhome id is needed!\n"  unless defined $dbhid;

  my $cmd = "$ODACLI delete-dbhome -i $dbhid -j";
  return run_job($cmd);
}

#
#  function: create_dbhome
#  input:    dbhome_version (12.1.0.2/11.2.0.4)
#  output:   success - 1/Failure - 0 
#

sub create_dbhome {
  my $dbhv = shift;
  my $de = shift;
  my $cmd;
  die "The dbhome version is needed!\n"  unless defined $dbhv;
  if (defined $de){
	$cmd = "$ODACLI create-dbhome -v $dbhv -de $de -j";
	}else{
	$cmd = "$ODACLI create-dbhome -v $dbhv -j";
	}
  return run_job($cmd);
}

#
#  function: describe_netsecurity
#  input:    dbhome_id
#  output:   Server <encryption_algorithms(, seperated)> <integrity_algorithms(, seperated)> <Connection Type>
#            Client <encryption_algorithms(, seperated)> <integrity_algorithms(, seperated)> <Connection Type> 
#            'space seperated'
#

sub describe_netsec {
  my $dbhid = shift;

  die "The dbhome id is needed!\n"  unless defined $dbhid;

  my $cmd = "$ODACLI describe-netsecurity -H $dbhid";
  my @result = `$cmd`;

  my @ret;
  
  for(my $i=0; $i<@result; $i=$i+1) {
    my @item = split /:/, $result[$i];
    if(defined $item[0] && $item[0] =~ /Role/) {
      $item[1] = join(' ', split(' ', $item[1]));
      my $temp = $item[1];
      for (my $j=1; $j<4; $j=$j+1) {
        $i=$i+1;
        @item = split /:/, $result[$i];
        $item[1] = join(',', split(' ', $item[1])); 
        $temp = $temp . " $item[1]";
      }
      push @ret, $temp;
    }
  } 
  return @ret;
}

#
#  function: list_schedules
#  input:    name (metastore|backup)
#  ouput:    id, name, description, cronexp

sub list_schedules {
   my $name = shift;

   die "The schedule name only can be metastore or backup!\n"  unless(defined $name && $name =~/metastore|backup/);

   my $cmd = "$ODACLI list-schedules";
   my @result = `$cmd`;
   my @ret;
   for my $line (@result) {
      if($line =~ /$name/) {
         @ret = split /\s+\s+/, $line;
         return @ret;
      }
   }
   return 0;
}

#
#  function: describe_schedule
#  input:    schedule_id
#  output:   id, jobname, cronexp, describe, disable
#

sub describe_schedule {
  my $scheduleid = shift;

  die "The schedule id is needed!\n"  unless defined $scheduleid;

  my $cmd = "$ODACLI describe-schedule -i $scheduleid";
  my @result = `$cmd`;

  my @ret;

  for my $line (@result) {
     chomp $line;
     $line =~ s/:\s+/:/;
     my @item = split /:/, $line;
     push @ret, $item[1] if(defined $item[1]);
  }
  return @ret[0,1,3,6,7];
}

#
#  function: update_schedule
#  input:    scheduleid, param(cronexp,description,enable/disable)=value
#  output:   success - 1/failure - 0
#

sub update_schedule {
  my $id = shift;
  my $param = shift;

  die "The schedule id and some parameter are needed\n" unless (defined $id && defined $param);

  my $cmd = "$ODACLI update-schedule -i $id";

  my @pairs = split /,/, $param;

  for my $pair (@pairs) {
    my @values = split /=/, $pair;
    $cmd = $cmd . " -x $values[1] " if($values[0] =~ /cronexp/i);
    $cmd = $cmd . " -t $values[1] " if($values[0] =~ /description/i);
    $cmd = $cmd . " -d " if($values[0] =~ /disable/i);
    $cmd = $cmd . " -e " if($values[0] =~ /enable/i);
  }

  return `$cmd`;
}

#
#  function: update_netsecurity
#  input:    id, param(encr,integ,type,role)=value
#  output:   success - 1/failure - 0
#

sub update_netsec {
   my $dbhid = shift;
   my $params = shift;
   

   my $cmd = "$ODACLI update-netsecurity -H $dbhid"; 

   return run_job($cmd) unless defined $params;
   $params =~ s/^\s+//g;

   my @pairs = split / /, $params;

   for my $pair (@pairs) {
    my @values = split /=/, $pair;
    $cmd = $cmd . " -e $values[1] " if($values[0] =~ /encr/i);
    $cmd = $cmd . " -i $values[1] " if($values[0] =~ /integ/i);
    $cmd = $cmd . " -t $values[1] " if($values[0] =~ /type/i);
    $cmd = $cmd . " -s " if($values[0] =~ /role/i && $values[1] =~ /server/i);
    $cmd = $cmd . " -c " if($values[0] =~ /role/i && $values[1] =~ /client/i); 
  }

   my $result = run_job($cmd);
   if($result) {
    my @result = describe_netsec($dbhid);
    my @ret;
    for my $temp(@result) {
      my @tmp = split / /, $temp;
      push @ret, @tmp;
    }
    if($params =~ /encr=(\S+)/) {
       my $encr = $1;
       if($params =~ /role=(\S+)/) {
         my $role = $1;
         return 0 unless (($role =~ /server/i && $encr eq $ret[1]) || ($role =~ /client/i && $encr eq $ret[5]));
       } 
       else {
         return 0 unless ($encr eq $ret[1]);
       }
    }
    if($params =~ /integ=(\S+)/) {
       my $encr = $1;
       if($params =~ /role=(\S+)/) {
         my $role = $1;
         return 0 unless (($role =~ /server/i && $encr eq $ret[2]) || ($role =~ /client/i && $encr eq $ret[6]));
       }
       else {
         return 0 unless ($encr eq $ret[2]);
       }
    }
    if($params =~ /type=(\S+)/) {
       my $encr = $1;
       if($params =~ /role=(\S+)/) {
         my $role = $1;
         return 0 unless (($role =~ /server/i && $encr eq $ret[3]) || ($role =~ /client/i && $encr eq $ret[7]));
       }
       else {
         return 0 unless ($encr eq $ret[3]);
       }
    }
    return check_netsec($dbhid);
   }
}

sub check_netsec {
   my $dbhid = shift;
   my ($s_type, $s_encra, $s_inta);
   my ($c_type, $c_encra, $c_inta);

   my @result = describe_dbhome($dbhid);
   my $dbhome = $result[3];
   my $netsqlf = catfile($dbhome, 'network', 'admin', 'sqlnet.ora');
   @result = describe_netsec($dbhid);

   open NF, "< $netsqlf";

   while(my $line = <NF>) {
     if($line =~ /SQLNET/) {
       my @temp = split /=/, $line;
       $temp[1] =~ s/\s+//g;
       $s_type = $temp[1] if ($line =~ /ENCRYPTION_SERVER/);
       if ($line =~ /ENCRYPTION_TYPES_SERVER/) {
         $s_encra = $temp[1];
         $s_encra =~ s/\((.*)\)/$1/g;
       }
       if ($line =~ /CRYPTO_CHECKSUM_TYPES_SERVER/) {
         $s_inta = $temp[1]; 
         $s_inta =~ s/\((.*)\)/$1/g; 
       }
       $c_type = $temp[1] if ($line =~ /ENCRYPTION_CLIENT/);
       if ($line =~ /ENCRYPTION_TYPES_CLIENT/) {
         $c_encra = $temp[1];
         $c_encra =~ s/\((.*)\)/$1/g;
       }
       if ($line =~ /CRYPTO_CHECKSUM_TYPES_CLIENT/) {
         $c_inta = $temp[1]; 
         $c_inta =~ s/\((.*)\)/$1/g;
       }
     }
   }
   for my $line (@result) {
     $line =~ tr/a-z/A-Z/;
     my @temp = split / /, $line;
     
     if($temp[0] =~ /server/i) {
        return 0 unless ($temp[1] eq $s_encra);
        return 0 unless ($temp[2] eq $s_inta);
        return 0 unless ($temp[3] eq $s_type);
     }
     else {
        return 0 unless ($temp[1] eq $c_encra);
        return 0 unless ($temp[2] eq $c_inta);
        return 0 unless ($temp[3] eq $c_type);
     }
   }
   return 1;
}

#
#  function: update_tdekey
#  input:    database_id, password, params(rootdb,pdbname,tagname)=value
#  output:   success - 1 / failure - 0
#

sub update_tdekey {
  my $dbid = shift;
  my $passwd = shift;
  my $param = shift;

  die "The database_id and password are needed!\n"  unless (defined $dbid && defined $passwd);

  my $cmd = "$ODACLI update-tdekey -i $dbid -hp $passwd ";

  if(defined $param) {
    my @pairs = split /,/, $param;

    for my $pair (@pairs) {
     my @values = split /=/, $pair;
     if($values[0] =~ /rootdb/) {
      $cmd = $cmd . " -r " if ($values[1] == 1);
      $cmd = $cmd . " -no-r " if ($values[1] == 0);
     }
     $cmd = $cmd . " -n $values[1] " if($values[0] =~ /pdbname/i);
     $cmd = $cmd . " -t $values[1] " if($values[0] =~ /tagname/i);
   }
  }
  return run_job($cmd); 
}

#
#  function: list_databases(List the last line)
#  input:    none
#  output:   id, name, version, cdb_or_not, class, shape, storage, status
#

sub list_databases {

 my $cmd = "$ODACLI list-databases";

 my @result = `$cmd`;

   die "There is no database\n"  if(!defined $result[0]);
   my $line= $result[-1];
   chomp $line;
   $line = $result[-2] unless $line =~ /\S+/;
   my @ret = split /\s+/, $line;
   return @ret;
}


#
#  function: describe_database
#  input:    database_id
#  output:   hash table contains id, name, version,cdb_or_not,pdbname,...
#

sub describe_database{
my $cmd="$ODACLI describe-database -i $_[0]";
my @result=`$cmd`;
my %hash;

if (defined $result[0]){
for my $line (@result) {
     chomp $line;
     if($line=~/:/){
     $line=~s/^\s*//;
     my @value=split(/:\s*/, $line);
     $hash{$value[0]}=$value[1] if(defined $value[1]);
     }
}
}else{
    die "There is no database\n";
     }
return %hash;
}

#
#  function: delete_database
#  input:    database_id
#  output:   success - 1/failure - 0
#


sub delete_database {
  my $id = shift;

  die "The database id is needed\n" unless defined $id;

  my $cmd = "$ODACLI delete-database -i $id";
  return run_job($cmd);
}

#
#  function: update_database
#  input:    dbid, bkcid
#  output:   success - 1/failure - 0
#

sub update_database {
  my $id = shift;
  my $bkcid = shift;
  my $backup_password=shift;

  die "The backupconfig id and database id are needed\n" unless (defined $id && defined $bkcid);

  my $cmd = "$ODACLI update-database -j $id  $bkcid";
  $cmd = "$ODACLI update-database -j $id  $bkcid -hbp \"$backup_password\"" if(defined $backup_password);
  return run_job($cmd);
}

#
#  function: upgrade_database
#  input:    dbid, desthomeid
#  output:   success - 1/failure - 0
#

sub upgrade_database {
  my $id = shift;
  my $desthomeid = shift;
  

  die "The desthomeid and database id are needed\n" unless (defined $id && defined $desthomeid);

  my $cmd = "$ODACLI upgrade-database -j -i $id -to $desthomeid";
  return run_job($cmd);
}

#
#  function: recover_database
#  input:    dbname, recovertype,options
#  output:   success - 1/failure - 0
#

sub recover_database {
  my $id = shift;
  my $recovertype = shift;
  my $recover_password=shift;

  die "The database name and recover type are needed\n" unless (defined $id && defined $recovertype);

  my $cmd = "$ODACLI recover-database -j $id $recovertype";
  $cmd = "$ODACLI recover-database -j $id $recovertype -hp $recover_password " if(defined $recover_password);
  return run_job($cmd);
}



#
#  function: create_database
#  input:    dbname, password,options(cdb,bkconfig,dbuname,dbclass,dbconsole,dbhome,dbshape,dbstorage,instanceonly,pdbadmin,pdbname,dbversion,lcharset,dbterr,dblan,dbtype,ncharset)=value
#  output:   success - 1/Failure - 0 
#

sub create_database {
  my $dbname = shift;
  my $passwd = shift;
  my $param = shift;
  my $cmd;

  die "The database_id and password are needed!\n"  unless (defined $dbname && defined $passwd);
 
if(defined $param){  
 $cmd = "$ODACLI create-database -hm '$passwd' -n $dbname $param -j";
}else{
 $cmd= "$ODACLI create-database -hm '$passwd' -n $dbname -j";
 }

  return run_job($cmd);
}


sub run_job {
  my $cmd = shift;
#  my $log_fh = shift;

  print "$cmd\n";
  my @result = `$cmd 2>&1`;
  my $jobid;
  for my $line (@result) {
   if($line =~ /\"jobId\"\s+:\s+\"(\S+)\"/) {
     $jobid = $1;
     last;
   }
  }
  unless (defined $jobid) {
#     print $log_fh @result;
     print @result;
     return 0;
  }

  LOOP: sleep 10;
  $cmd = "$ODACLI describe-job -i $jobid";
  open (RESULT, "$cmd |");
  while (my $line = <RESULT>) {
     if($line =~ /Status/) {
       if($line =~ /Success/) {
          close RESULT;
          return(1);
        }
        elsif($line =~ /Running/) {
         goto LOOP;
        }
        else {
         print "Job failed!\n";
         return(0);
        }
     }
   } 
}



#  function: update_repository
#  input:  absolute file path with comma
#  output:   success - 1/Failure - 0
#

sub update_repository {
  
  die "The file path is needed!\n"  unless (defined $_[0]);
  my $cmd = "$ODACLI update-repository -f $_[0]";

  return run_job($cmd);
}

#  function: create_appliance
#  input:  absolute json file path
#  output:   success - 1/Failure - 0
#

sub create_appliance {

  die "The file path is needed!\n"  unless (defined $_[0]);
  my $cmd = "$ODACLI create-appliance -r $_[0]";

  return run_job($cmd);
}


#  function: describe_appliance
#  input:    nothing
#  output:   hash table contains name, domain name, cpu core, DNS, NTP...
#

sub describe_appliance{
my $cmd="$ODACLI describe-appliance";
my @result=`$cmd`;
my %hash;

if (defined $result[0]){
for my $line (@result) {
     chomp $line;
     if($line=~/:/){
     $line=~s/^\s*//;
     my @value=split(/:\s*/, $line);
     $hash{$value[0]}=$value[1];
     }
}
}else{
    die "Appliace is not deployed!\n";
     }
return %hash;
}     

#  function: update_dbhome
#  input:  dbhome_id and system_version
#  output:   success - 1/Failure - 0
#

sub update_dbhome {

  die "dbhome_id is needed!\n"  unless (defined $_[0] && defined $_[1]);
  my $cmd = "$ODACLI update-dbhome  -i $_[0] -v $_[1]";

  return run_job($cmd);
}

#  function: describe_asr
#  input:    nothing
#  output:   hash table contains asrtype, username, snmpversion...
#
#  function: update_server
#  input:  version
#  output:   success - 1/Failure - 0
#

sub update_server {

  die "version is needed!\n"  unless (defined $_[0]);
  my $cmd = "$ODACLI update-server -v $_[0]";

  return run_job($cmd);
}

#  function: update_dcsagent
#  input:  version
#  output:   success - 1/Failure - 0
#

sub update_dcsagent {

  die "version is needed!\n"  unless (defined $_[0]);
  my $cmd = "$ODACLI update-dcsagent -v $_[0]";

  return run_job($cmd);
}


sub describe_asr{
my $cmd="$ODACLI describe-asr";
my @result=`$cmd`;
my %hash;

if (defined $result[0]){
for my $line (@result) {
     chomp $line;
     if($line=~/:/){
     $line=~s/^\s*//;
     my @value=split(/\s*:\s*/, $line);
     $hash{$value[0]}=$value[1];
     }
 }
return %hash;
}else{
return 0;
     }
}

#  function: delete_asr
#  input:    nothing
#  output:   success - 1/Failure - 0
#
sub delete_asr{
my $cmd="$ODACLI delete-asr -j";
return run_job($cmd);
}

#  function: configure_asr
#  input:    all the options as one input
#  output:   success - 1/Failure - 0
#
sub configure_asr{
printf "please give the arguments\n" if (!defined $_[0]);
my $cmd="$ODACLI configure-asr $_[0] -j";
return run_job($cmd);
}

#  function: test_asr
#  input:    nothing
#  output:   success - 1/Failure - 0
#
sub test_asr{

my $cmd="$ODACLI test-asr -j";
return run_job($cmd);
}

#  function: update_asr
#  input:    all the options as one input
#  output:   success - 1/Failure - 0
#
sub update_asr{
printf "please give the arguments\n" if (!defined $_[0]);
my $cmd="$ODACLI update-asr $_[0] -j";
return run_job($cmd);
}
#  function: create_objectstoreswift
#  input:    oss name
#  output:   success - 1/Failure - 0
#

our $url_oss="https://swiftobjectstorage.us-phoenix-1.oraclecloud.com/v1";
our $tenant_name_oss="dbaasimage";
our $user_name_oss='chunling.qin@oracle.com';
our $password_oss='wgT.ZM&>U6Tmm#F]O&9n';


sub create_objectstoreswift{
printf "please give the objecstoreswift name!\n" if (!defined $_[0]);
my $cmd="$ODACLI create-objectstoreswift -j -n $_[0] -e $url_oss -hp \"$password_oss\" -t $tenant_name_oss -u $user_name_oss";
return run_job($cmd);
}

#  function: list_objectstoreswifts(List the last line)
#  input:    none
#  output:   ID,Name,UserName,TenantName,Url 

sub list_objectstoreswifts {

 my $cmd = "$ODACLI list-objectstoreswifts";

 my @result = `$cmd`;

   die "There is no objectstoreswifts\n"  if(!defined $result[0]);
   my $line= $result[-1];
   chomp $line;
   $line = $result[-2] unless $line =~ /\S+/;
   my @ret = split /\s+/, $line;
   return @ret;
}

sub describe_objectstoreswift{
printf "please give the objecstoreswift name/id!\n" if (!defined $_[0]);
my $cmd="$ODACLI describe-objectstoreswift $_[0] ";
my @result=`$cmd`;
my %hash;

if (defined $result[0]){
for my $line (@result) {
     chomp $line;
     if($line=~/:/){
     $line=~s/^\s*//;
     my @value=split(/:\s*/, $line);
     $hash{$value[0]}=$value[1];
     }
}
}else{
    die "objectstoreswift describe fail!\n";
     }
return %hash;
}     

#
#  function: delete_objectstoreswift
#  input:    objectstoreswiftName/id
#  output:   success - 1/failure - 0
#


sub delete_objectstoreswift {
  my $id = shift;

  die "The objectstoreswiftName or id is needed\n" unless defined $id;

  my $cmd = "$ODACLI delete-objectstoreswift -j $id";
  return run_job($cmd);
}

#
#  function: update_objectstoreswift
#  input:    objectstoreswift id，username or password
#  output:   success - 1/failure - 0
#

sub update_objectstoreswift {
  my $id = shift;
  my $user_password = shift;

  die "The objectstoreswift id or name and user_password are needed\n" unless (defined $id && defined $user_password);

  my $cmd = "$ODACLI update-objectstoreswift -j $id $user_password";
  return run_job($cmd);
}


#  function: Check the db clone file exist or not
#  input: dbversion
#  output:   success - 1/Failure - 0

sub is_clone_exist{

my $cmd;
if($_[0] eq '11.2.0.4.160419'){
    $cmd="ls -l /opt/oracle/oak/pkgrepos/orapkgs/clones/db112.tar.gz";
    }elsif($_[0] eq '12.1.0.2.160419'){
    $cmd="ls -l /opt/oracle/oak/pkgrepos/orapkgs/clones/db121.tar.gz";
    }else{
    my @temp=split(/\./,$_[0]);
    my $ver=join '',@temp[0..1];
    my $ver2=join '.', ($ver, $temp[-1]);
    $cmd="ls -l /opt/oracle/oak/pkgrepos/orapkgs/clones/*$ver2*";
    }
my @result=`$cmd 2>error.log`;
if (defined $result[0]){
return 1;
}else{
return 0};
}

#  function: scp and unpack the db clone file
#  input: clone file name

sub scp_unpack_dbclone{
my $file=$_[0];
my $dir='/tmp/tmp';
`mkdir -p $dir`;
my $cmd="/usr/bin/scp 10.208.184.63:/odalite/ODALite_DBbundle/$file $dir";

my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
my $pass=$exp->expect($timeout, 'continue connecting');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'password');
$exp->send("welcome2\r") if($pass);
$exp->interact();

`rm -rf $dir/$file` if(update_repository("$dir/$file"));
}


#  function: generate a name rondomly
#  input: character source, max number of the character
#  output: generated name

sub name_generate{
my $max_num=pop @_;
my @dataSource=@_;
my $name;
my @dataSource1 = ('a'..'z','A'..'Z');
my $num_name=int(rand($max_num)+1);
if ($num_name eq '1'){
$name = shuffle(@dataSource1);
}elsif($num_name eq '2'){
$name = shuffle(@dataSource1).shuffle(@dataSource);
}else{
$name = join '',(shuffle(@dataSource))[0..($num_name-2)];
$name = shuffle(@dataSource1). $name;}
}

#  function: scp a file to the destination
#  input: file name, destination, server name and server password
sub scp_file{

my $file=$_[0];
my $dir=$_[1];
my $server='10.208.144.25';
my $server_password='welcome2';
$server=$_[2] if(defined $_[2]);
$server_password=$_[3] if (defined $_[3]);
printf "$server, $server_password\n";

my $cmd="/usr/bin/scp $server:$file $dir";

my $exp=new Expect;
my $timeout=6;
$exp->spawn($cmd) or die "cann't not spawn $cmd\n";
my $pass=$exp->expect($timeout, 'continue connecting');
$exp->send("yes\r") if($pass);
$pass=$exp->expect($timeout, 'password');
$exp->send("$server_password\r") if($pass);
$exp->interact();
}

