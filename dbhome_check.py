#!/user/bin/env python
#coding utf-8

import create_multiple_db as c_m_d
import random
import common_fun as cf
import oda_lib
import string
import sys
import os
import re
import datetime

def check_dbhome(*a):
    host = a[0]
    if len(a) == 1:
        s_v = host.system_version()
        s_v = cf.trim_version(s_v)
        version = c_m_d.d_version[s_v]
        print version
    else:
        version = a[1]
    version_list = c_m_d.db_versions(host,version)
    if len(version_list) == 0:
        sys.exit(1)
    print version_list
    for i in version_list:
        if not c_m_d.is_clone_exists_or_not(host, i):
            c_m_d.scp_unpack_clone_file(host, i)
        v = i.split('_')[0]
        if not host.create_dbhome("-de SE -v %s" % v):
            print "create SE dbhome with version %s failed!" % v
        else:
            dbhomeid = get_dbhomeid(host)
            if not delete_dbhome(host,dbhomeid):
                print "delete dbhome failed %s" % dbhomeid

        if not host.create_dbhome("-de EE -v %s" % v):
            print "create EE dbhome with version %s failed!" % v
        else:
            dbhomeid = get_dbhomeid(host)
            if not delete_dbhome(host, dbhomeid):
                print "delete dbhome failed %s" % dbhomeid


def get_dbhomeid(host):
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes|tail -n 2|awk '{print $1}'"
    dbhomeid = host.ssh2node(cmd)
    return dbhomeid


def delete_dbhome(host, dbhomeid):
    if not host.delete_dbhome("-i %s" % dbhomeid):
        print "delete dbhome %s failed!" % dbhomeid
        return 0
    else:
        return 1


def main(hostname, username, password):
    logfile_name = 'check_dbhome_create_delete_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    host = oda_lib.Oda_ha(hostname, username, password)
    ver = random.choice(['170814','171017','180116','180417'])
    check_dbhome(host,ver)
    error = cf.logfile_close_check_error(fp, out, err,log)
    return error


if __name__ == '__main__':
    main("rwsoda6m005", 'root','welcome1')