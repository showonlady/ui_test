#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to check the datbase related commands, it creates the db with ramdom options according to the cpucores.
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/12/16 - Creation
# - CHQIN 10/26/17 - Modify it for X7-2



use strict ;
use warnings ;
use Data::Dumper ;
use English ;
use Expect;
use bmiaaslib;
use List::Util qw(first max maxstr min minstr reduce shuffle sum) ;

my $testlog = 'check-database-odalite.log';

open TESTLOG, ">> $testlog" || die "Can't create logfile: $!";

#select TESTLOG;
#$|=1;

*STDOUT = *TESTLOG;
*STDERR = *TESTLOG;


#print "========= Negative Test=========\n\n";

#create_database('1abc', 'WelCome-123#');
#create_database('abcediflege', 'WelCome-123#');
#create_database('test1', 'welcome1', "-s odb16 -cl DSS");
#create_database('test2', 'welcome1', "-s odb16 -cl IMDB");
#create_database('abcef', 'WelCome-123',"-dh chqin");
#create_database('abcef', 'WelCome-1#',"-v 11.2.0.4 -dh chqin");
#create_database('abcef', 'WelCome-123#',"lcharset=AL16UTF16");
#create_database('abcef', 'WelCome-123#',"-c -v 11.2.0.4");
#create_database('abcef', 'WelCome-123#',"-r ASM -v 11.2.0.4");
#create_database('abcef', 'WelCome-123#',"-no-c,-p pdb1");

print "========= Positive Test=========\n\n";



my @items=("ID", "DB Name", "DB Type", "DB Version", "CDB", "Class", "Shape", "Storage","Home ID");
my $password="welcome123";
my @dataSource = (0..9,'a'..'z','A'..'Z');
my @dataSource_pdb=(@dataSource, '_');
my @dataSource_uniquename=(@dataSource, '_');
my @dbhomeid;
#my @version=keys %version_dbclone;
my @version=('12.1.0.2','12.2.0.1','11.2.0.4');
my $version=shuffle @version;
my $de=shuffle ('EE','SE');
my $ODACLI="/opt/oracle/dcs/bin/odacli";
my %appliance=&describe_appliance;
my $db_edition=$appliance{"DB Edition"};

my $cpucore_num=&describe_cpucore;
my @shape_source=qw/odb1s odb1 odb2 odb4 odb6 odb8 odb10 odb12 odb16 odb20 odb24 odb32 odb36/;
my @shape_source_se12=qw/odb1s odb1 odb2 odb4 odb6 odb8/;
my @shape;
@shape=@shape_source[0..($cpucore_num/2+1)] if($cpucore_num <= 12);
@shape=@shape_source[0..7] if($cpucore_num == 14 );
@shape=@shape_source[0..8] if($cpucore_num == 18 ||$cpucore_num == 16);
@shape=@shape_source[0..9] if($cpucore_num == 20 ||$cpucore_num == 22);
@shape=@shape_source[0..10] if($cpucore_num >= 24 && $cpucore_num < 32);
@shape=@shape_source[0..11] if($cpucore_num >= 32 && $cpucore_num < 36);
@shape=@shape_source if($cpucore_num eq 36);
my @shape_se12;
@shape_se12=@shape_source_se12[0..($cpucore_num/2+1)] if ($cpucore_num < 8);
@shape_se12=@shape_source_se12 if ($cpucore_num >= 8);

my $shape=shuffle @shape;
my $shape_se12=shuffle @shape_se12;

printf $shape. "\n";
my @storage= qw/ACFS ASM/;
my $storage=shuffle @storage;

my @dbclass= qw/OLTP DSS IMDB/;
my $dbclass=shuffle @dbclass;
my $dbclass11=shuffle ('OLTP','DSS');

my $characterSet="AL32UTF8, AR8ADOS710, AR8ADOS710T, AR8ADOS720, AR8ADOS720T, AR8APTEC715, AR8APTEC715T, AR8ARABICMACS, AR8ASMO708PLUS, AR8ASMO8X, AR8HPARABIC8T, AR8ISO8859P6, AR8MSWIN1256, AR8MUSSAD768, AR8MUSSAD768T, AR8NAFITHA711, AR8NAFITHA711T, AR8NAFITHA721, AR8NAFITHA721T, AR8SAKHR706, AR8SAKHR707, AR8SAKHR707T, AZ8ISO8859P9E, BG8MSWIN, BG8PC437S, BLT8CP921, BLT8ISO8859P13, BLT8MSWIN1257, BLT8PC775, BN8BSCII, CDN8PC863, CEL8ISO8859P14, CL8ISO8859P5, CL8ISOIR111, CL8KOI8R, CL8KOI8U, CL8MACCYRILLICS, CL8MSWIN1251, EE8ISO8859P2, EE8MACCES, EE8MACCROATIANS, EE8MSWIN1250, EE8PC852, EL8DEC, EL8ISO8859P7, EL8MACGREEKS, EL8MSWIN1253, EL8PC437S, EL8PC851, EL8PC869, ET8MSWIN923, HU8ABMOD, HU8CWI2, IN8ISCII, IS8PC861, IW8ISO8859P8, IW8MACHEBREWS, IW8MSWIN1255, IW8PC1507, JA16EUC, JA16EUCTILDE, JA16SJIS, JA16SJISTILDE, JA16VMS, KO16KSC5601, KO16KSCCS, KO16MSWIN949, LA8ISO6937, LA8PASSPORT, LT8MSWIN921, LT8PC772, LT8PC774, LV8PC1117, LV8PC8LR, LV8RST104090, N8PC865, NE8ISO8859P10, NEE8ISO8859P4, RU8BESTA, RU8PC855, RU8PC866, SE8ISO8859P3, TH8MACTHAIS, TH8TISASCII, TR8DEC, TR8MACTURKISHS, TR8MSWIN1254, TR8PC857, US8PC437, UTF8, VN8MSWIN1258, VN8VN3, WE8DEC, WE8DG, WE8ISO8859P1, WE8ISO8859P15, WE8ISO8859P9, WE8MACROMAN8S, WE8MSWIN1252, WE8NCR4970, WE8NEXTSTEP, WE8PC850, WE8PC858, WE8PC860, WE8ROMAN8, ZHS16CGB231280, ZHS16GBK, ZHT16BIG5, ZHT16CCDC, ZHT16DBT, ZHT16HKSCS, ZHT16MSWIN950, ZHT32EUC, ZHT32SOPS, ZHT32TRIS, US7ASCII";

my $dbLanuage="ALBANIAN, AMERICAN, ARABIC, ASSAMESE, AZERBAIJANI, BANGLA, BELARUSIAN, 'BRAZILIAN PORTUGUESE', BULGARIAN, 'CANADIAN FRENCH', CATALAN, CROATIAN, 'CYRILLIC KAZAKH', 'CYRILLIC SERBIAN', 'CYRILLIC UZBEK', CZECH, DANISH, DUTCH, EGYPTIAN, ENGLISH, ESTONIAN, FINNISH, FRENCH, GERMAN, 'GERMAN DIN', GREEK, GUJARATI, HEBREW, HINDI, HUNGARIA, ICELANDIC, INDONESIAN, IRISH, ITALIAN, JAPANESE, KANNADA, KOREAN, 'LATIN AMERICAN SPANISH', 'LATIN SERBIAN', 'LATIN UZBEK', LATVIAN, LITHUANIAN, MACEDONIAN, MALAY, MALAYALAM, MARATHI, 'MEXICAN SPANISH', NORWEGIAN, ORIYA, POLISH, PORTUGUESE, PUNJABI, ROMANIAN, RUSSIAN, 'SIMPLIFIED CHINESE', SLOVAK, SLOVENIAN, SPANISH, SWEDISH, TAMIL, TELUGU, THAI, 'TRADITIONAL CHINESE', TURKISH, UKRAINIAN, VIETNAMESE";

my $dbTerritory="ALBANIA, ALGERIA, AMERICA, ARGENTINA, AUSTRALIA, AUSTRIA, AZERBAIJAN, BAHRAIN, BANGLADESH, BELARUS, BELGIUM, BRAZIL, BULGARIA, CANADA, CATALONIA, CHILE, CHINA, COLOMBIA, 'COSTA RICA', CROATIA, CYPRUS, 'CZECH REPUBLIC', DJIBOUTI, ECUADOR, EGYPT, 'EL SALVADOR', ESTONIA, FINLAND, FRANCE, 'FYR MACEDONIA', GERMANY, GREECE, GUATEMALA, 'HONG KONG', HUNGARY, ICELAND, INDIA, INDONESIA, IRAQ, IRELAND, ISRAEL, ITALY, JAPAN, JORDAN, KAZAKHSTAN, KOREA, KUWAIT, LATVIA, LEBANON, LIBYA, LITHUANIA, LUXEMBOURG, MALAYSIA, MAURITANIA, MEXICO, MONTENEGRO, MOROCCO, 'NEW ZEALAND', NICARAGUA, NORWAY, OMAN, PANAMA, PERU, PHILIPPINES, POLAND, PORTUGAL, 'PUERTO RICO', QATAR, ROMANIA, RUSSIA, 'SAUDI ARABIA', SERBIA, SINGAPORE, SLOVAKIA, SLOVENIA, SOMALIA, 'SOUTH AFRICA', SPAIN, SUDAN, SWEDEN, SWITZERLAND, SYRIA, TAIWAN, THAILAND, 'THE NETHERLANDS', TUNISIA, TURKEY, UKRAINE, 'UNITED ARAB EMIRATES', 'UNITED KINGDOM', UZBEKISTAN, VENEZUELA, VIETNAM, YEMEN";
my $nlsCharacterset="AL16UTF16, UTF8";
my @dbtype;
if (&check_ha_or_olite){
@dbtype=qw/Rac RacOne SI/;
}else{
@dbtype=qw/SI/;
}

my $dbtype=shuffle @dbtype;

my @optcmd=();
my $optcmd;
my $cdbenable=0;
my $dhenable=0;

my %opt_arguments=("-cs"=>"$characterSet",
"-l"=>"$dbLanuage",
"-dt"=>"$dbTerritory",
"-ns"=>"$nlsCharacterset",
);

my $key;
my $value;
my @value;
my $opt;
my %db_arguments;

my $dbname=name_generate(@dataSource, '8');
$db_arguments{'DB Name'}=$dbname;

if(shuffle(0..1)){
  my $dbuniquename=name_generate(@dataSource_uniquename, '30');
  my $db_unique="-u $dbuniquename";
  push  @optcmd,$db_unique;
  }
if(shuffle(0..1)){
  push @optcmd, '-co';
  }
if(shuffle(0..1)){
  push @optcmd, "-y $dbtype";
  $db_arguments{'DB Type'}=$dbtype;
  }
if(shuffle(0..1)){
  push @optcmd, "-v $version";
  }else{
  $version='12.2.0.1';
  }
$db_arguments{'DB Version'}=$version;

if(shuffle(0..1)){
  push @optcmd, "-de $de";
  }else{
  $de=$db_edition;
  }

  
while (($key, $value)=each %opt_arguments){
@value=split (/,\s*/,$value);
$opt=choose_opt(@value, $key);
my $temp_value;
if($opt){
   push @optcmd,$opt;
   my @temp2=split /\s+/, $opt;
   if ($opt=~/'/){
   my @temp3=split /'/,$opt;
   $temp_value=$temp3[1];
   }else{
   $temp_value=$temp2[1];
   }
   
  if($temp2[0] eq '-cs'){
   $db_arguments{'CharacterSet'}=$temp_value;
   }elsif($temp2[0] eq '-l'){
   $db_arguments{'Language'}=$temp_value;
   }elsif($temp2[0] eq '-dt'){
   $db_arguments{'Territory'}=$temp_value;
   }elsif($temp2[0] eq '-ns'){
   $db_arguments{'National CharacterSet'}=$temp_value;
   }
 }
}
 

if($version=~/^12/ && $de=~/EE/){

  if(shuffle(0..1)){
    push @optcmd, '-c';
    $db_arguments{'CDB'}='true'; 
    $cdbenable=1;
    if(shuffle(0..1)){
       my $pdbname=name_generate(@dataSource_pdb, '30');
       $db_arguments{'PDB Name'}=$pdbname;
       my $pdb="-p $pdbname";
       push  @optcmd, $pdb;
       }
    if(shuffle(0..1)){
       my $pdbadmin='test';
       $db_arguments{'PDB Admin User Name'}=$pdbadmin;
       push  @optcmd, "-d $pdbadmin";
       }  
	}else{
	  push @optcmd, '-no-c';
      $db_arguments{'CDB'}='false'; 
     }

  if(shuffle(0..1)){
    push @optcmd, "-cl $dbclass";
    }else{
	$dbclass = 'OLTP'
	}
	$db_arguments{'Class'}=$dbclass;

  if(shuffle(0..1)){
    push @optcmd, '-s'." $shape";
    }else{
	$shape='odb1';
	}
  $db_arguments{'Shape'}=$shape;

  if(shuffle(0..1)){
    push @optcmd, '-r'." $storage";
	$db_arguments{'Storage'}=$storage;
    }
}elsif($version=~/^11/ && $de=~/EE/){

  if(shuffle(0..1)){
  	  push @optcmd, '-no-c';
      $db_arguments{'CDB'}='false'; 
     }

  if(shuffle(0..1)){
   $dbclass=$dbclass11;   
   push @optcmd, "-cl $dbclass11";
    }else{
	$dbclass = 'OLTP'
	}
	$db_arguments{'Class'}=$dbclass;
  if(shuffle(0..1)){
    push @optcmd, "-s $shape";
    }else{
    $shape='odb1';
    }
  $db_arguments{'Shape'}=$shape;

  if(1){
    push @optcmd, "-r ACFS";
    }
  $db_arguments{'Storage'}='ACFS';

}elsif($version=~/^12/ && $de=~/SE/){

  if(shuffle(0..1)){
    push @optcmd, '-c';
    $db_arguments{'CDB'}='true'; 
    $cdbenable=1;
    if(shuffle(0..1)){
       my $pdbname=name_generate(@dataSource_pdb, '30');
       $db_arguments{'PDB Name'}=$pdbname;
       my $pdb="-p $pdbname";
       push  @optcmd, $pdb;
       }
    if(shuffle(0..1)){
       my $pdbadmin='test';
       $db_arguments{'PDB Admin User Name'}=$pdbadmin;
       push  @optcmd, "-d $pdbadmin";
       }  
	}else{
	  push @optcmd, '-no-c';
      $db_arguments{'CDB'}='false'; 
     }

  if(shuffle(0..1)){
     push @optcmd, "-cl OLTP";
    }
   $dbclass='OLTP';
   $db_arguments{'Class'}='OLTP';
 
  if(shuffle(0..1)){
    $shape=$shape_se12;
    push @optcmd, "-s $shape_se12";
    }else{
    $shape='odb1';
    }
  $db_arguments{'Shape'}=$shape;

  if(shuffle(0..1)){
    push @optcmd, "-r $storage";
    $db_arguments{'Storage'}=$storage;
	}
}elsif($version=~/^11/ && $de=~/SE/){

  if(shuffle(0..1)){
  	  push @optcmd, '-no-c';
      $db_arguments{'CDB'}='false'; 
     }

  if(shuffle(0..1)){
    push @optcmd, "-cl OLTP";
    }
  $dbclass='OLTP';
  $db_arguments{'Class'}='OLTP';

  if(shuffle(0..1)){
    push @optcmd, "-s $shape";
    }else{     
    $shape='odb1';
	}
  $db_arguments{'Shape'}=$shape;

  if(1){
    push @optcmd, "-r ACFS";
    }
  $db_arguments{'Storage'}='ACFS';

}

$optcmd=join(' ',@optcmd);
#printf "$password, $dbname,$optcmd\n";

foreach(keys %db_arguments){
printf "$_==>$db_arguments{$_}\n";
}


if(create_database($dbname, $password, $optcmd)) {
   my @result = list_databases();
   print "Create Database successfully\n" if ($result[1] =~ /$dbname/ && $result[8] =~ /Configured/);
   my %temp = describe_database($result[0]);
   foreach (keys %db_arguments){
   if (! $db_arguments{$_} =~ /$temp{$_}/i){
   printf "describe fail!\n,$db_arguments{$_},$temp{$_}";
   last;}
   }
   for my $i (1..@items){
   if (! $temp{$items[$i-1]} =~/$result[$i-1]/i){
   print "describe/list database fail!\n,$temp{$items[$i-1]},$result[$i-1]";
   last;
   }
   }
   
  
 my $dbhomeid=$temp{'Home ID'};
 my $dbhome=`$ODACLI list-dbhomes|grep $dbhomeid|awk '{print \$6}'`;
 chomp $dbhome;
 
 
print "========= sqlplus check===============================\n\n";
 my $sql_check_version='select BANNER from v\$version';
 my $sql_cpu_count='show parameter cpu_count';
 my $sql_sga_target='show parameter sga_target';
 my $sql_pga_target='show parameter pga_aggregate_target';
 my $sql_processes='show parameter processes';
 
 
 
my $sql_version=sql_check($dbname, $dbhome,$sql_check_version);
chomp $sql_version;
print "sqlplus check find inconsistent!\n" unless ($sql_version=~/$version/);
if ($de =~/EE/i){
	print "sqlplus check find db edition inconsistent! $sql_version!\n" unless($sql_version=~/Enterprise Edition/);
	}else{
	print "sqlplus check find db edition inconsistent, $sql_version!\n" unless($sql_version=~/Standard Edition/);
	}

my $sql_cpu_count_num=(&sql_cpu_count_fun($dbname, $dbhome,$sql_cpu_count))/2;
my $cpu_cores=$1 if ($shape=~/(\d+)/);
print "sql check cpu_core is not correct!$sql_cpu_count_num" unless ($cpu_cores eq  $sql_cpu_count_num);	

my $sql_sga_num=&sql_sga_fun($dbname, $dbhome,$sql_sga_target);
my $sql_pga_num=&sql_pga_fun($dbname, $dbhome,$sql_pga_target);
my $sql_processes_num=&sql_processes_fun($dbname, $dbhome,$sql_processes);
print "sql check processes number is not correct!$sql_processes_num\n" unless (($cpu_cores*200) eq  $sql_processes_num);	



if ($dbclass =~/OLTP/i){
if ($shape=~/odb1s/){
print "sga or pga is not correct! sga: $sql_sga_num,pga: $sql_pga_num\n" unless ($sql_sga_num eq '2' && $sql_pga_num eq '1');
}else{
my $result1=$cpu_cores * 4;
my $result2=$cpu_cores * 2;
print "sga or pga is not correct! sga: $sql_sga_num,pga: $sql_pga_num\n" unless ($sql_sga_num eq $result1 && $sql_pga_num eq $result2);
}

}elsif($dbclass =~/DSS/i){
if ($shape=~/odb1s/){
print "sga or pga is not correct! sga: $sql_sga_num,pga: $sql_pga_num\n" unless ($sql_sga_num eq '1' && $sql_pga_num eq '2');
}else{
my $result1=$cpu_cores * 2;
my $result2=$cpu_cores * 4;
print "sga or pga is not correct! sga: $sql_sga_num,pga: $sql_pga_num\n" unless ($sql_sga_num eq $result1 && $sql_pga_num eq $result2);
}

}elsif($dbclass=~/IMDB/i){

if ($shape=~/odb1s/){
print "sga or pga is not correct! sga: $sql_sga_num,pga: $sql_pga_num\n" unless ($sql_sga_num eq '2' && $sql_pga_num eq '1');
}else{
my $result1=$cpu_cores * 4;
my $result2=$cpu_cores * 2;
print "sga or pga is not correct! sga: $sql_sga_num,pga: $sql_pga_num\n" unless ($sql_sga_num eq $result1 && $sql_pga_num eq $result2);
}

}
print "========= sqlplus check end===============================\n\n";

 #print "Delete database successfully\n" if (delete_database($result[0]));
 }

sub sql_sga_fun{
my $dbname=shift;
my $dbhome=shift;
my $sql_sga_target=shift;

my @sql_output=sql_check($dbname, $dbhome,$sql_sga_target);

my $result=$sql_output[-1];
my @item=split /\s+/, $result;
chomp $item[-1];
$item[-1]=~/(\d+)/;
return ($1);

}
sub sql_cpu_count_fun{
my $dbname=shift;
my $dbhome=shift;
my $sql_cpu_count=shift;

my @sql_output=sql_check($dbname, $dbhome,$sql_cpu_count);

my $result=$sql_output[-1];
my @item=split /\s+/, $result;
chomp $item[-1];
return ($item[-1]);

}

sub sql_processes_fun{
my $dbname=shift;
my $dbhome=shift;
my $sql_processes=shift;

my @sql_output=sql_check($dbname, $dbhome,$sql_processes);

my $result=$sql_output[-1];
my @item=split /\s+/, $result;
chomp $item[-1];
return ($item[-1]);

}

sub sql_pga_fun{

my $dbname=shift;
my $dbhome=shift;
my $sql_pga_target=shift;

my @sql_output=sql_check($dbname, $dbhome,$sql_pga_target);

my $result=$sql_output[-1];
my @item=split /\s+/, $result;
chomp $item[-1];
$item[-1]=~/(\d+)/;
return ($1);

}


sub choose_opt{
my $flag=pop @_;
my @source=@_;
if(shuffle(0..1)){
  my $choose=shuffle @source;
  my $source1="$flag $choose";
  return $source1;
  }else{
  return 0;
  }
  }
  
sub sql_check{
my $dbname=shift;
my $dbhome=shift;
my $sql=shift;
my $rac_owner=`cat $dbhome/install/utl/rootmacro.sh | grep "^ORACLE_OWNER=" | cut -d "=" -f 2`;
chomp $rac_owner;
my $instancename=`/bin/su - $rac_owner -c "ps -ef|grep ora_pmon_$dbname|grep -v grep"`;
chomp $instancename;
my @temp_item=split /\s+/, $instancename;
my $pmon_name=$temp_item[-1];
$instancename=substr $pmon_name,9;
#print $instancename;
open sql_check_file, ">/home/$rac_owner/sql_check.sh" || die "Can't create sql_check_file: $!";
print sql_check_file "#!/bin/bash\n";
print sql_check_file "export ORACLE_SID=$instancename\n";
print sql_check_file "export ORACLE_HOME=$dbhome\n";
print sql_check_file "$dbhome/bin/sqlplus -S -L / as sysdba <<EOF\n";
print sql_check_file "$sql;\n";
print sql_check_file "EOF\n";
close sql_check_file;
my $rac_group=`ls -l /home/|grep $rac_owner|awk '{print \$4}'`;
chomp $rac_group;
`/bin/chown $rac_owner:$rac_group /home/$rac_owner/sql_check.sh`;
`/bin/chmod +x /home/$rac_owner/sql_check.sh`;
my $sql_output=`/bin/su - $rac_owner -c /home/$rac_owner/sql_check.sh`;
}
  
  
sub check_ha_or_olite{
my $output=`cat /proc/cmdline`;
if ($output=~/HA/i){
return 1;
}else{
return 0;
}
}