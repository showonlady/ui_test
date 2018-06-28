#!/user/bin/env python
#conding utf-8

"""
Usage:
    oak_prepare_patch.py -s <servername> [-u <username>] [-p <password>]

Options:
    -h,--help       Show this help message
    -v,--version     Show version
    -s <servername>  hostname of machine, if vlan,use ip instead
    -u <username>  username [default: root]
    -p <password>  password [default: welcome1]
"""

from docopt import docopt
import oda_lib_oak
import os
import common_fun as cf
import re

remote_dir = "/tmp"

def scp_unpack_pb(host):
    p_v = host.Current_version
    v = cf.trim_version(p_v)
    loc = "/chqin/ODA%s/OAKPB/" % v
    for i in os.listdir(loc):
        scp_file = os.path.join(loc, i)
        remote_file = os.path.join(remote_dir, i)
        host.scp2node(scp_file, remote_file)
        cmd = "/opt/oracle/oak/bin/oakcli unpack -package %s" % remote_file
        result = host.ssh2node(cmd)
        if re.search('successful', result,re.IGNORECASE):
            host.ssh2node('rm -rf %s' % remote_file)


def scp_stat(host):
    stat = "/home/chqin/qcl/scripts/stats.sh"
    remote_file = os.path.join(remote_dir, os.path.basename(stat))
    host.scp2node(stat,remote_file)

def pre_patch_check(host):
    cmd1 = "/opt/oracle/oak/bin/oakcli show version -detail"
    cmd2 = "sh /tmp/stats.sh"
    cmd3 = "/opt/oracle/oak/bin/oakcli validate -a"
    print host.ssh2node(cmd1)
    print host.ssh2node(cmd2)
    print host.ssh2node(cmd3)
    if host.is_vm_or_not():
        cmd4 = "/opt/oracle/oak/bin/oakcli show vm"
        cmd5 = "/opt/oracle/oak/bin/oakcli show repo"
        print host.ssh2node(cmd4)
        print host.ssh2node(cmd5)

def post_unpack(host):
    cmd1 = "/opt/oracle/oak/bin/oakcli update -patch %s -verify" % host.Current_version
    print host.ssh2node(cmd1)


def node2_host(host):
    oak2 = cf.node2_name(host.hostname)
    host2 = oda_lib_oak.Oda_ha(oak2, host.username, host.password)
    return host2




def main(host):
    logfile_name = 'check_oak_preparing_patch_%s.log' % host.hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    host2 = node2_host(host)
    scp_stat(host)
    scp_stat(host2)
    pre_patch_check(host)
    pre_patch_check(host2)
    scp_unpack_pb(host)
    scp_unpack_pb(host2)
    post_unpack(host)
    post_unpack(host2)
    cf.logfile_close_check_error(fp, out, err,log)


if __name__ == '__main__':
    arg = docopt(__doc__)
    print arg
    hostname = arg['-s']
    username = arg['-u']
    password = arg['-p']
    host = oda_lib_oak.Oda_ha(hostname, username, password)
    main(host)




