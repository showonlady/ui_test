
#!/usr/bin/perl -w
# DESCRIPTION
# - This script is used to check the datbase related commands, it creates the db with ramdom options according to the cpucores.
#
#
# MODIFIED (MM/DD/YY)
# - CHQIN 12/12/16 - Creation



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



my @items=("ID", "DB Name", "DB Version", "CDB", "Class", "Shape", "Storage");
my $password="welcome123";
my @dataSource = (0..9,'a'..'z','A'..'Z');
my @dataSource_pdb=(@dataSource, '_');
my @dataSource_uniquename=(@dataSource, '_');
my @dbhomeid;
my @version=keys %version_dbclone;
my @version_12102=grep/^12/,@version;
my $version;
my $dbclass="OLTP, DSS, IMDB";
my $cpucore_num=&describe_cpucore;
my @shape_source=qw/odb1s odb1 odb2 odb4 odb6 odb8 odb10 odb12 odb16 odb20/;
my @shape;
@shape=@shape_source[0..($cpucore_num/2+1)] if($cpucore_num <= 12);
@shape=@shape_source[0..($cpucore_num/2)] if($cpucore_num == 14 ||$cpucore_num == 16);
@shape=@shape_source[0..($cpucore_num/2-1)] if($cpucore_num == 18 ||$cpucore_num == 20);
my $shape=join ', ', @shape;
printf "$shape \n";
my $storage="ACFS, ASM";
my $characterSet="AL32UTF8, AR8ADOS710, AR8ADOS710T, AR8ADOS720, AR8ADOS720T, AR8APTEC715, AR8APTEC715T, AR8ARABICMACS, AR8ASMO708PLUS, AR8ASMO8X, AR8HPARABIC8T, AR8ISO8859P6, AR8MSWIN1256, AR8MUSSAD768, AR8MUSSAD768T, AR8NAFITHA711, AR8NAFITHA711T, AR8NAFITHA721, AR8NAFITHA721T, AR8SAKHR706, AR8SAKHR707, AR8SAKHR707T, AZ8ISO8859P9E, BG8MSWIN, BG8PC437S, BLT8CP921, BLT8ISO8859P13, BLT8MSWIN1257, BLT8PC775, BN8BSCII, CDN8PC863, CEL8ISO8859P14, CL8ISO8859P5, CL8ISOIR111, CL8KOI8R, CL8KOI8U, CL8MACCYRILLICS, CL8MSWIN1251, EE8ISO8859P2, EE8MACCES, EE8MACCROATIANS, EE8MSWIN1250, EE8PC852, EL8DEC, EL8ISO8859P7, EL8MACGREEKS, EL8MSWIN1253, EL8PC437S, EL8PC851, EL8PC869, ET8MSWIN923, HU8ABMOD, HU8CWI2, IN8ISCII, IS8PC861, IW8ISO8859P8, IW8MACHEBREWS, IW8MSWIN1255, IW8PC1507, JA16EUC, JA16EUCTILDE, JA16SJIS, JA16SJISTILDE, JA16VMS, KO16KSC5601, KO16KSCCS, KO16MSWIN949, LA8ISO6937, LA8PASSPORT, LT8MSWIN921, LT8PC772, LT8PC774, LV8PC1117, LV8PC8LR, LV8RST104090, N8PC865, NE8ISO8859P10, NEE8ISO8859P4, RU8BESTA, RU8PC855, RU8PC866, SE8ISO8859P3, TH8MACTHAIS, TH8TISASCII, TR8DEC, TR8MACTURKISHS, TR8MSWIN1254, TR8PC857, US8PC437, UTF8, VN8MSWIN1258, VN8VN3, WE8DEC, WE8DG, WE8ISO8859P1, WE8ISO8859P15, WE8ISO8859P9, WE8MACROMAN8S, WE8MSWIN1252, WE8NCR4970, WE8NEXTSTEP, WE8PC850, WE8PC858, WE8PC860, WE8ROMAN8, ZHS16CGB231280, ZHS16GBK, ZHT16BIG5, ZHT16CCDC, ZHT16DBT, ZHT16HKSCS, ZHT16MSWIN950, ZHT32EUC, ZHT32SOPS, ZHT32TRIS, US7ASCII";

my $dbLanuage="ALBANIAN, AMERICAN, ARABIC, ASSAMESE, AZERBAIJANI, BANGLA, BELARUSIAN, 'BRAZILIAN PORTUGUESE', BULGARIAN, 'CANADIAN FRENCH', CATALAN, CROATIAN, 'CYRILLIC KAZAKH', 'CYRILLIC SERBIAN', 'CYRILLIC UZBEK', CZECH, DANISH, DUTCH, EGYPTIAN, ENGLISH, ESTONIAN, FINNISH, FRENCH, GERMAN, 'GERMAN DIN', GREEK, GUJARATI, HEBREW, HINDI, HUNGARIA, ICELANDIC, INDONESIAN, IRISH, ITALIAN, JAPANESE, KANNADA, KOREAN, 'LATIN AMERICAN SPANISH', 'LATIN SERBIAN', 'LATIN UZBEK', LATVIAN, LITHUANIAN, MACEDONIAN, MALAY, MALAYALAM, MARATHI, 'MEXICAN SPANISH', NORWEGIAN, ORIYA, POLISH, PORTUGUESE, PUNJABI, ROMANIAN, RUSSIAN, 'SIMPLIFIED CHINESE', SLOVAK, SLOVENIAN, SPANISH, SWEDISH, TAMIL, TELUGU, THAI, 'TRADITIONAL CHINESE', TURKISH, UKRAINIAN, VIETNAMESE";

my $dbTerritory="ALBANIA, ALGERIA, AMERICA, ARGENTINA, AUSTRALIA, AUSTRIA, AZERBAIJAN, BAHRAIN, BANGLADESH, BELARUS, BELGIUM, BRAZIL, BULGARIA, CANADA, CATALONIA, CHILE, CHINA, COLOMBIA, 'COSTA RICA', CROATIA, CYPRUS, 'CZECH REPUBLIC', DJIBOUTI, ECUADOR, EGYPT, 'EL SALVADOR', ESTONIA, FINLAND, FRANCE, 'FYR MACEDONIA', GERMANY, GREECE, GUATEMALA, 'HONG KONG', HUNGARY, ICELAND, INDIA, INDONESIA, IRAQ, IRELAND, ISRAEL, ITALY, JAPAN, JORDAN, KAZAKHSTAN, KOREA, KUWAIT, LATVIA, LEBANON, LIBYA, LITHUANIA, LUXEMBOURG, MALAYSIA, MAURITANIA, MEXICO, MONTENEGRO, MOROCCO, 'NEW ZEALAND', NICARAGUA, NORWAY, OMAN, PANAMA, PERU, PHILIPPINES, POLAND, PORTUGAL, 'PUERTO RICO', QATAR, ROMANIA, RUSSIA, SAUDI ARABIA, SERBIA, SINGAPORE, SLOVAKIA, SLOVENIA, SOMALIA, 'SOUTH AFRICA', SPAIN, SUDAN, SWEDEN, SWITZERLAND, SYRIA, TAIWAN, THAILAND, 'THE NETHERLANDS', TUNISIA, TURKEY, UKRAINE, 'UNITED ARAB EMIRATES', 'UNITED KINGDOM', UZBEKISTAN, VENEZUELA, VIETNAM, YEMEN";
my $nlsCharacterset="AL16UTF16, UTF8";

my @optcmd=();
my $optcmd;
my $cdbenable=0;
my $dhenable=0;

my %opt_arguments=("-cl"=>"$dbclass",
"-s"=>"$shape",
"-r"=>"$storage",
"-cs"=>"$characterSet",
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
  push @optcmd, '-c';
  $db_arguments{'CDB'}='true'; 
  $cdbenable=1;
  if(shuffle(0..1)){
     my $pdbname=name_generate(@dataSource_pdb, '30');
     $db_arguments{'PDB Name'}=$pdbname;
     my $pdb="-p $pdbname";
     push  @optcmd, $pdb;
     }
      
}
else{ 
  push @optcmd, '-no-c';
  $db_arguments{'CDB'}='false'; 
  }
if(shuffle(0..1)){
  push @optcmd, '-co';
  $db_arguments{'Console Enabled'}='true'; 
  }else{
  push @optcmd, '-no-co'; 
  $db_arguments{'Console Enabled'}='false'; 
  }
if(shuffle(0..1)){
  push @optcmd, '-io';
  }
if(shuffle(0..1)){
  my $dbuniquename=name_generate(@dataSource_uniquename, '30');
  my $db_unique="-u $dbuniquename";
  push  @optcmd,$db_unique;
  }

if ($cdbenable){
@dbhomeid=get_dbhomeid('OraDB12102');
}else{
@dbhomeid=&get_dbhomeid;
}
if ($dbhomeid[0]){
my $dbhomeid=choose_opt(@dbhomeid,'-dh');
if($dbhomeid){
$dhenable=1;
push @optcmd,$dbhomeid;
my @temp1=split /\s+/, $dbhomeid;
$db_arguments{'Home ID'}=$temp1[1];
}
if(!$dhenable){
   if ($cdbenable){
   $version=choose_opt(@version_12102,'-v');
   }else{
   $version=choose_opt(@version,'-v');
   }
   push @optcmd,$version if($version);
   if($version){
   my @ver1=split /\s+/, $version;
   scp_unpack_dbclone($version_dbclone{$ver1[1]}) if(!is_clone_exist($ver1[1]));
   }else{
   scp_unpack_dbclone($version_dbclone{$latest_ver}) if(!is_clone_exist($latest_ver));
   $db_arguments{'DB Version'}='12.1.0.2';
   }
   if ($version=~/12.1.0.2/){
   $db_arguments{'DB Version'}='12.1.0.2';}elsif($version=~/11.2.0.4/){
   $db_arguments{'DB Version'}='11.2.0.4';}

}
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
   
   if($temp2[0] eq '-cl'){
   $db_arguments{'Class'}=$temp_value;
   }elsif($temp2[0] eq '-s'){
   $db_arguments{'Shape'}=$temp_value;
   }elsif($temp2[0] eq '-r'){
   $db_arguments{'Storage'}=$temp_value;
   }elsif($temp2[0] eq '-cs'){
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

$optcmd=join(' ',@optcmd);
#printf "$password, $dbname,$optcmd\n";

foreach(keys %db_arguments){
printf "$_==>$db_arguments{$_}\n";
}



if(create_database($dbname, $password, $optcmd)) {
   my @result = list_databases();
   print "Create Database successfully\n" if ($result[1] =~ /$dbname/ && $result[7] =~ /Configured/);
   my %temp = describe_database($result[0]);
   foreach (keys %db_arguments){
   if ($db_arguments{$_} ne $temp{$_}){
   printf "describe fail!\n";
   last;}
   }
   for my $i (1..@items){
   if ($temp{$items[$i-1]} ne $result[$i-1]){
   die "describe/list database fail!\n";
   }
   }
   print "describe/list database successfully!\n";

   print "Delete database successfully\n" if (delete_database($result[0]));
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


sub get_dbhomeid{
my $cmd;
if(defined $_[0]){
$cmd="odacli list-dbhomes|grep $_[0]";
}else{
$cmd="odacli list-dbhomes|grep OraDB";
}
my @result=`$cmd`;
if(defined $result[0]){
my $i='$1';
my $j='$5';
my @dbhome=`$cmd|awk -F "  "+ '$j~/Configured/{print $i}'`;
@dbhome=grep (/^\S+/,@dbhome);
chomp @dbhome;
return @dbhome;
}else{return 0;
}
}

close TESTLOG;

