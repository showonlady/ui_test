#!/user/bin/env python
#encoding utf-8

"""
Usage:
    oda_deploy.py -h
    oda_deploy.py  -s <servername> [-u <username>] [-p <password>] [-o <jsonfile>]
    oda_deploy.py [ui] -s <servername> [-u <username>] [-p <password>]

Options:
    -h,--help       Show this help message
    -s <servername>  hostname of machine, if vlan,use ip instead
    -u <username>  username [default: root]
    -p <password>  password [default: welcome1]
    -o <jsonfile>   The json file name with path
    ui  only unpack the clone files, use ui to do the provision
"""


from docopt import docopt
import oda_lib
import common_fun as cf
import random
import os
import oda_patch as o_p
import time
import sys

def no_deploy(host):
    s_v = host.system_version()
    version = cf.trim_version(s_v)
    scp_unpack_file(host)
    if o_p.is_12211_or_not(host):
        time.sleep(20)
        patch(host)
    if version == "12.1.2.8.1":
        updatedcsimage(host)


def oda_deploy(*a):
    host = a[0]
    s_v = host.system_version()
    version = cf.trim_version(s_v)
    scp_unpack_file(host)
    if o_p.is_12211_or_not(host):
        time.sleep(20)
        patch(host)
    if version == "12.1.2.8.1":
        updatedcsimage(host)

    if len(a) == 2:
        json = a[1]
    else:
        a = json_string(host)
        json = json_file(a)
    if not json:
        print "Json file could not be found!"
        sys.exit(0)
    else:
        remote_file = os.path.join("/tmp", os.path.basename(json))
        host.scp2node(json,remote_file)
        if not host.create_appliance("-r %s" % remote_file):
            print "create appliance failed!"
            sys.exit(0)


def updatedcsimage(host):
    local_file = "/chqin/ODA12.1.2.8.1/dcsImage_12.1.2.8.1.zip"
    remote_file = "/tmp/dcsImage_12.1.2.8.1.zip"
    host.scp2node(local_file, remote_file)
    cmd = "update-image --image-files /tmp/dcsImage_12.1.2.8.1.zip"
    host.ssh2node(cmd)
    time.sleep(120)





def patch(host):
    if not host.update_dcsagent("-v 12.2.1.1.0"):
        print "Update dcsagent to 12.2.1.1 fail!"
        sys.exit(1)
    time.sleep(300)
    if not host.update_server("-v 12.2.1.1.0"):
        print "Update server to 12.2.1.1 fail!"
        sys.exit(1)


        



def json_string(host):
    s_v = host.system_version()
    version = cf.trim_version(s_v)
    hostname = host.hostname
    if not host.is_bonding_or_not():
        a = "nobond_" + hostname + "*" + version
    else:
        a = hostname + "*" + version
    print a
    return a

def scp_unpack_file(host):
    s_v = host.system_version()
    version = cf.trim_version(s_v)
    hostname = host.hostname
    username = host.username
    password = host.password
    v_loc = "ODA" + '.'.join(version.split('.')[0:4])
    remote_dir = '/tmp/'
    server_loc = '/chqin/%s/oda-sm/' % v_loc
    scpfile(host, server_loc, remote_dir)
    unpack_all_files(host, server_loc, remote_dir)

    if host.is_ha_not() and o_p.is_12211_or_not(host):
        node2 = o_p.node2_name(hostname)
        host2 = oda_lib.Oda_ha(node2, username, password)
        scpfile(host2, server_loc, remote_dir)
        unpack_all_files(host2, server_loc, remote_dir)



def json_file(x):
    cmd = "ls /chqin/json/%s" % x
    out = cf.exc_cmd(cmd).split()
    file = random.choice(out)
    if os.path.exists(file):
        return file
    else:
        return 0





def scpfile(host,server_loc, remote_dir ):
    for i in os.listdir(server_loc):
        if not i:
            sys.exit(1)
        else:
            remote_file = os.path.join(remote_dir, i)
            local_file = os.path.join(server_loc, i)
            host.scp2node(local_file, remote_file)

def unpack_all_files(host, server_loc, remote_dir):
    for i in os.listdir(server_loc):
        file = os.path.join(remote_dir, i)
        if  host.update_repository("-f %s" % file):
            cmd = "rm -rf %s" % file
            host.ssh2node(cmd)
        else:
            print "Fail to update-repository with file %s" % file
            sys.exit(0)










if __name__ == '__main__':
    arg = docopt(__doc__)
    print arg
    hostname = arg['-s']
    username = arg['-u']
    password = arg['-p']
    host = oda_lib.Oda_ha(hostname, username, password)
    if arg['ui']:
        no_deploy(host)
    elif arg['-o']:
        jsonfile = arg['-o']
        oda_deploy(host, jsonfile)
    else:
        oda_deploy(host)
