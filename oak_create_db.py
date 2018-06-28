#!/user/bin/env python
#encoding utf-8
"""
Usage:
    oak_create_db.py [crdb] -s <servername> [-u <username>] [-p <password>]
    oak_create_db.py [crvm] -s <servername> [-u <username>] [-p <password>]

Options:
    -h,--help       Show this help message
    -v,--version     Show version
    -s <servername>  hostname of machine, if vlan,use ip instead
    -u <username>  username [default: root]
    -p <password>  password [default: welcome1]
    crvm   create vm
    crdb   create database
"""
from docopt import docopt

import random
import sys
import oda_lib_oak
import re
import os
import common_fun as cf
import sys

create_db_script = "/home/chqin/qcl/scripts/chunling/create_db_definevesion_storage.pl"
remote_dir = "/tmp"
remote_dir2 = "/root"
version_file = 'version'
vm_script = "create_vm.sh"

d = {"12.1.2.12": ["12.1.0.2.170814", "11.2.0.4.170814"],
     "12.2.1.2": ["12.1.0.2.171017", "11.2.0.4.171017", "12.2.0.1.171017"],
     "12.2.1.3": ["12.1.0.2.180116", "11.2.0.4.180116", "12.2.0.1.180116"],
     "12.2.1.4": ["12.1.0.2.180417", "11.2.0.4.180417", "12.2.0.1.180417"]
    }

def exec_crdb_script(host):
    write_version_file(host)
    scp_scrips(host)
    remote_file = os.path.join(remote_dir, os.path.basename(create_db_script))
    cmd = "perl %s" % remote_file
    result = host.ssh2node(cmd)
    print result
    sys.stdout.flush()

def exec_crvm_scripts(host):
    if host.is_vm_or_not():
        scp_template_file(host)
        scp_crvm_script(host)
        remote_file = os.path.join(remote_dir, os.path.basename(vm_script))
        cmd = "sh %s" % remote_file
        print cmd
        result = host.ssh2node(cmd)
        print result
        sys.stdout.flush()

    else:
        pass




def write_version_file(host):
    s_v = host.system_version()
    if s_v not in d.keys():
        print "not support this version: %s " % s_v
        sys.exit(0)
    else:
        versions = d[s_v]
        fp = open('version','w')
        if len(versions) == 2:
            j = 3
        else:
            j = 2
        for i in versions:
            for a in range(j):
                fp.write("%s  %s\n" % (i, random.choice(['ASM','ACFS'])))
        fp.close()



def scp_scrips(host):

    remote_file = os.path.join(remote_dir, os.path.basename(create_db_script))
    remote_file2 = os.path.join(remote_dir2, os.path.basename(version_file))
    host.scp2node(create_db_script, remote_file)
    host.scp2node(version_file, remote_file2)

def dom0_name(host):
    hostname = host.hostname
    b = re.search('(\D+\d+)', hostname).group(1)
    return b+'1', b+'2'

def scp_template_file(host):
    oak1, oak2 = dom0_name(host)
    cmd = "sh scp_template.sh %s %s" %(oak1, oak2)
    cf.exc_cmd(cmd)

def scp_crvm_script(host):
    remote_file = os.path.join(remote_dir, os.path.basename(vm_script))
    host.scp2node(vm_script, remote_file)


if __name__ == '__main__':
    arg = docopt(__doc__)
    print arg
    hostname = arg['-s']
    username = arg['-u']
    password = arg['-p']
    host = oda_lib_oak.Oda_ha(hostname, username, password)
    logfile_name = 'check_oak_create_db_vm_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    if arg['crdb']:
        exec_crdb_script(host)
    if arg['crvm']:
        exec_crvm_scripts(host)
    if not arg['crdb'] and not arg['crvm']:
        exec_crdb_script(host)
        exec_crvm_scripts(host)
    cf.logfile_close_check_error(fp, out, err, log)


