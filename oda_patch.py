#!/user/bin/env python
#conding utf-8
"""
Usage:
    oda_patch.py -h
    oda_patch.py -s <servername> [-u <username>] [-p <password>] [-v <version>]

Options:
    -h,--help       Show this help message
    -s <servername>  hostname of machine, if vlan,use ip instead
    -u <username>  username [default: root]
    -p <password>  password [default: welcome1]
    -v <version>   The version number you want to patch
"""


from docopt import docopt
import oda_lib
import sys
import common_fun as cf
import os
import re
import random
import time



def scpfile(host, remote_dir, server_loc):
    for i in os.listdir(server_loc):
        if not i:
            sys.exit(1)
        else:
            remote_file = os.path.join(remote_dir, i)
            local_file = os.path.join(server_loc, i)
            host.scp2node(local_file, remote_file)

def unpack_all_files(host, remote_dir, server_loc):
    for i in os.listdir(server_loc):
        file = os.path.join(remote_dir, i)
        if host.update_repository("-f %s" % file):
            cmd = "rm -rf %s" % file
            host.ssh2node(cmd)



def update_dcsagent(host, version):
    if host.update_dcsagent("-v %s" % version):
        return 1
    else:
        return 0

def is_12211_or_not(host):
    cmd = "rpm -qa|grep dcs-agent"
    output = host.ssh2node(cmd)
    if re.search('12.2.1.1', output):
        return 1
    else:
        return 0




def update_server_precheck(host, version):
    """prechecks"""
    flag = 1
    s_v = host.system_version()
    s_v = cf.trim_version(s_v)
    if s_v in ['12.1.2.8','12.1.2.8.1','12.1.2.9','12.1.2.10','12.1.2.11', '12.1.2.12']:
        op_pre = ['-v %s -p' % version]
    else:
        op_pre = ['-v %s -p' % version, '-v %s -p -l' % version, '-v %s -p -n 0' % version]
    for i in op_pre:
        if not host.update_server(i):
            flag = 0
            print "update server precheck fail! %s" % i
            
    if host.is_ha_not():
        op_pre_ha = '-v %s -p -n 1' % version
        if not host.update_server(op_pre_ha):
            flag = 0
            print "update server precheck fail! %s" % op_pre_ha
    return flag

def update_server(host, version):
    flag = 1
    s_v = host.system_version()
    s_v = cf.trim_version(s_v)
    if s_v in ['12.1.2.8', '12.1.2.8.1', '12.1.2.9', '12.1.2.10', '12.1.2.11', '12.1.2.12']:
        op_lite = ['-v %s' % version]
    else:
        op_lite = ['-v %s' % version,'-v % s -l'% version,'-v %s -n 0' % version]
    op1 = random.choice(op_lite)
    if not host.is_ha_not():
        if not host.update_server(op1):
            flag = 0
            print "update server fail! %s" % op1
    else:
        if random.choice([True, False]):
            if not host.update_server("-v %s" % version):
                flag = 0
                print "update server with '-v' fail!"
        else:
            if not host.update_server("-v %s -n 1" % version):
                flag = 0
                print "update server with '-v -n 1' fail!"
            if not host.update_server("-v %s -n 0" % version):
                flag = 0
                print "update server with '-v -n 0' fail!"
    return flag


def dbhome_patch(host, version = oda_lib.Oda_ha.Current_version):
    print "*" * 20 + "dbhome patch begin" + "*" * 20
    print host.describe_component()
    print host.crs_status()
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes"
    print host.ssh2node(cmd)
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes|grep -i Configured|awk '{print $1}'"
    result = host.ssh2node(cmd)
    if not result:
        print "not dbhome to patch!"
    else:
        dbhomeid = result.split()
        for i in dbhomeid:
            patch_one_dbhome(host,i, version)
    print host.describe_component()
    print host.crs_status()
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes"
    print host.ssh2node(cmd)
    print "*" * 20 + "dbhome patch finish" + "*" * 20




def patch_one_dbhome(host, id, version):
    if host.is_ha_not():
       if random.choice([True, False]):
           if not host.update_dbhome("-v %s -i %s -p" % (version, id)):
               print "dbhome %s precheck failed!" % id
           if not host.update_dbhome("-v %s -i %s" % (version, id)):
               print "dbhome %s patch failed!" % id

       else:
           if not host.update_dbhome("-v %s -i %s -n 0 -p" % (version, id)):
               print "dbhome %s precheck failed!" % id

           if not host.update_dbhome("-v %s -i %s -l" % (version, id)):
               print "dbhome %s patch failed!" % id

           if not host.update_dbhome("-v %s -i %s -n 1 -p" % (version, id)):
               print "dbhome %s precheck failed!" % id

           if not host.update_dbhome("-v %s -i %s -n 1" % (version, id)):
               print "dbhome %s patch failed!" % id


    else:
        if not host.update_dbhome("-v %s -i %s -p" % (version, id)):
            print "dbhome %s precheck failed!" % id

        if not host.update_dbhome("-v %s -i %s" % (version, id)):
            print "dbhome %s patch failed!" % id

"""
def node2_name(a):
    b = a[:-1] + str(int(a[-1]) + 1)
    return b
"""

def dcs_patch(host, version = oda_lib.Oda_ha.Current_version):
    v_loc = "ODA" + '.'.join(version.split('.')[0:4])
    remote_dir = '/tmp/'
    server_loc = '/chqin/%s/patch/' % v_loc
    scpfile(host, remote_dir, server_loc)
    unpack_all_files(host, remote_dir, server_loc)
    hostname = host.hostname
    username = host.username
    password = host.password
    if host.is_ha_not() and is_12211_or_not(host):
        node2 = cf.node2_name(hostname)
        host2 = oda_lib.Oda_ha(node2, username, password)
        scpfile(host2, remote_dir, server_loc)
        unpack_all_files(host2,remote_dir, server_loc)
    cf.extend_space_u01(host)
    print "*" * 20 + "dcsagent patch begin" + "*" * 20
    print host.describe_component()
    print host.crs_status()
    if not update_dcsagent(host, version):
        print "update dcsagent failed"
        sys.exit(0)
    time.sleep(180)
    print host.describe_component()
    print host.crs_status()
    print "*" * 20 + "dcsagent patch finish" + "*" * 20

def server_patch(host, version = oda_lib.Oda_ha.Current_version):
    print "*" * 20 + "server patch begin" + "*" * 20
    print host.describe_component()
    print host.crs_status()
    if not update_server_precheck(host, version):
        print "update server precheck failed"
        sys.exit(0)
    if not update_server(host, version):
        print "update server failed"
        sys.exit(0)
    print "*" * 20 + "server patch finish" + "*" * 20

def simple_update_server(host,version):
    print "*" * 20 + "server patch begin" + "*" * 20
    print host.describe_component()
    print host.crs_status()
    if not host.update_server("-v %s" % version):
        print "update server with '-v' fail!"
        sys.exit(0)
    print "*" * 20 + "server patch finish" + "*" * 20

def simple_update_dbhome(host,version):
    print "*" * 20 + "dbhome patch begin" + "*" * 20
    print host.describe_component()
    print host.crs_status()
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes"
    print host.ssh2node(cmd)
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes|grep -i Configured|awk '{print $1}'"
    result = host.ssh2node(cmd)
    if not result:
        print "not dbhome to patch!"
    else:
        dbhomeid = result.split()
        for i in dbhomeid:
            if not host.update_dbhome("-v %s -i %s" % (version, i)):
                print "dbhome %s patch failed!" % i
    print host.describe_component()
    print host.crs_status()
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes"
    print host.ssh2node(cmd)
    print "*" * 20 + "dbhome patch finish" + "*" * 20



def main(hostname,username,password, version):
    logfile_name = 'check_oda_patch_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    host = oda_lib.Oda_ha(hostname, username, password)
    dcs_patch(host, version)
    server_patch(host, version)
    time.sleep(600)
    cf.wait_until_ping(host.hostname)
    host2 = oda_lib.Oda_ha(hostname, username, password)
    dbhome_patch(host2, version)
    error = cf.logfile_close_check_error(fp, out, err,log)
    return error


if __name__ == '__main__':
    arg = docopt(__doc__)
    print arg
    hostname = arg['-s']
    username = arg['-u']
    password = arg['-p']
    if arg['-v']:
        version = arg['-v']
    else:
        version = oda_lib.Oda_ha.Current_version

    main(hostname, username, password, version)



