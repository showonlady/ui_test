#!/user/bin/env python
#encoding utf-8
"""
Usage:
    create_multiple_db.py -h
    create_multiple_db.py -s <servername> [-u <username>] [-p <password>] [-v <dbversion>]

Options:
    -h,--help       Show this help message
    -s <servername>  hostname of machine, if vlan,use ip instead
    -u <username>  username [default: root]
    -p <password>  password [default: welcome1]
    -v <dbversion>  deversion
"""
from docopt import docopt
import oda_lib
import random
import string
import sys
import os
import re
import common_fun as cf
import datetime

dbclone={"12.1.0.2.170117" : "oda-sm-12.1.2.10.0-170205-DB-12.1.0.2.zip",
"12.1.0.2.161018" : "oda-sm-12.1.2.9.0-161116-DB-12.1.0.2.zip",
"12.1.0.2.160719" : "oda-sm-12.1.2.8.0-160809-DB-12.1.0.2.zip",
"12.1.0.2.160419" : "oda-sm-12.1.2.7.0-160601-DB-12.1.0.2.zip",
"11.2.0.4.161018" : "oda-sm-12.1.2.9.0-161007-DB-11.2.0.4.zip",
"11.2.0.4.160719" : "oda-sm-12.1.2.8.0-160817-DB-11.2.0.4.zip",
"11.2.0.4.160419" : "oda-sm-12.1.2.7.0-160601-DB-11.2.0.4.zip",
"12.1.0.2.170418" : "oda-sm-12.1.2.11.0-170503-DB-12.1.0.2.zip",
"11.2.0.4.170418" : "oda-sm-12.1.2.11.0-170503-DB-11.2.0.4.zip",
"11.2.0.4.170814_x7" : "oda-sm-12.2.1.1.0-171026-DB-11.2.0.4.zip",
"12.1.0.2.170814_x7" : "oda-sm-12.2.1.1.0-171026-DB-12.1.0.2.zip",
"12.2.0.1.170814_x7" : "oda-sm-12.2.1.1.0-171025-DB-12.2.1.1.zip",
"11.2.0.4.170814_x6" : "oda-sm-12.1.2.12.0-170905-DB-11.2.0.4.zip",
"12.1.0.2.170814_x6" : "oda-sm-12.1.2.12.0-170905-DB-12.1.0.2.zip",
"11.2.0.4.171017" : "oda-sm-12.2.1.2.0-171124-DB-11.2.0.4.zip",
"12.1.0.2.171017" : "oda-sm-12.2.1.2.0-171124-DB-12.1.0.2.zip",
"12.2.0.1.171017" : "oda-sm-12.2.1.2.0-171124-DB-12.2.0.1.zip",
"11.2.0.4.180116" : "odacli-dcs-12.2.1.3.0-180315-DB-11.2.0.4.zip",
"12.1.0.2.180116" : "odacli-dcs-12.2.1.3.0-180320-DB-12.1.0.2.zip",
"12.2.0.1.180116" : "odacli-dcs-12.2.1.3.0-180418-DB-12.2.0.1.zip",
"11.2.0.4.180417" : "odacli-dcs-12.2.1.4.0-180617-DB-11.2.0.4.zip",
"12.1.0.2.180417" : "odacli-dcs-12.2.1.4.0-180617-DB-12.1.0.2.zip",
"12.2.0.1.180417" : "odacli-dcs-12.2.1.4.0-180617-DB-12.2.0.1.zip"
}

d_version={
    "12.1.2.8": "160719",
    "12.1.2.8.1": "160719",
    "12.1.2.9": "161018",
    "12.1.2.10": "170117",
    "12.1.2.11": "170418",
    "12.1.2.12": "170814",
    "12.2.1.1": "170814",
    "12.2.1.2": "171017",
    "12.2.1.3": "180116",
    "12.2.1.4": "180417"
   }
def create_multiple_db(*a):
    host = a[0]
    if len(a) == 1:
        s_v = host.system_version()
        s_v = cf.trim_version(s_v)
        version = d_version[s_v]
        print version
    else:
        version = a[1]
    version_list = db_versions(host,version)
    if len(version_list) == 0:
        sys.exit(1)
    print version_list
    for i in version_list:
        if not is_clone_exists_or_not(host, i):
            scp_unpack_clone_file(host, i)
        for j in range(3):
           op = db_op(host, i)
           if not host.create_database(op):
               print "database creation fail! %s" % op




def is_clone_exists_or_not(host, version):
    b = version.split("_")
    c = b[0][0:2]+b[0][3]+b[0][-7:]
    file = "db" + c + ".tar.gz"
    cmd = "ls -l /opt/oracle/oak/pkgrepos/orapkgs/clones/%s" % file
    result = host.ssh2node(cmd)
    print result
    if re.search("No such", result):
        return 0
    else:
        return 1

def db_op(host,version):
    no_de_version = ['12.1.2.8','12.1.2.8.1','12.1.2.9','12.1.2.10','12.1.2.11', '12.1.2.12','12.2.1.1']
    s_v = host.system_version()
    s_v = cf.trim_version(s_v)
    if s_v in no_de_version:
        appliance = host.describe_appliance()
        de = appliance['SysInstance']['dbEdition']
        options = ''
    else:
        de = random.choice(['EE', 'SE'])
        options = '-de %s ' % de

    version = version.split('_')[0]
    dbname = cf.generate_string(cf.string1, 8)
    password = "WElcome12#_"
    co = random.choice(["-co", "-no-co"])
    if host.is_ha_not():
        dbtype = random.choice(['RAC', 'RACONE', 'SI'])
    else:
        dbtype = 'SI'
    storage = random.choice(['ACFS', 'ASM'])
    pdbname = cf.generate_string(cf.string2, 20)
    cdb = random.choice(['-c -p %s' % pdbname, '-no-c'] )
    db11class = random.choice(['OLTP','DSS'])
    db12class = random.choice(['OLTP','DSS','IMDB'])

    if de == "SE" and re.match("11.2", version):
        options += "-hm %s -n %s -v %s -r ACFS -y %s %s" % (password, dbname, version,dbtype, co)
    elif de == "SE" and re.match("12.", version):
        options += "-hm %s -n %s -v %s -r %s -y %s %s %s" % (password, dbname, version, storage,dbtype, co, cdb)
    elif de == "EE" and re.match("11.2", version):
        options += "-hm %s -n %s -v %s -cl %s -r ACFS -y %s %s" % (password, dbname, version, db11class, dbtype, co)
    else:
        options += "-hm %s -n %s -v %s -cl %s -r %s -y %s %s %s" % (password, dbname, version,db12class, storage,dbtype, co, cdb)
    return options







def scp_unpack_clone_file(host,version):
    clonefile = dbclone[version]
    a = clonefile.split('-')[2]
    b = cf.trim_version(a)
    c = 'ODA'+b
    d = "/chqin/%s/oda-sm/%s" %(c,clonefile)
    if os.path.exists(d):
        remote_file = os.path.join("/tmp", os.path.basename(d))
        host.scp2node(d, remote_file)
        if host.update_repository("-f %s" % remote_file):
            host.ssh2node("rm -rf %s" % remote_file)

    else:
        print "there is no clone file %s" % version
        sys.exit(0)




def db_versions(host, version):
    list = []
    if version == "170814" and host.is_x6_or_x7():
        version_f = "170814_x6"
    elif version == "170814" and not host.is_x6_or_x7():
        version_f = "170814_x7"
    else:
        version_f = version
    for i in dbclone.keys():
        if re.search(version_f,i):
            list.append(i)
    return list



if __name__ == '__main__':
    arg = docopt(__doc__)
    print arg
    hostname = arg['-s']
    username = arg['-u']
    password = arg['-p']
    host = oda_lib.Oda_ha(hostname, username, password)

    if arg['-v']:
        version = arg['-v']
        create_multiple_db(host, version)
    else:
        create_multiple_db(host)

    #main("scaoda7s005", 'root','welcome1')






