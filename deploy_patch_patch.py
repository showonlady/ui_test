#!/user/bin/env python
#encoding utf-8
"""
Usage:
    deploy_patch_patch.py -h
    deploy_patch_patch.py -s <servername> [-u <username>] [-p <password>] [--pbd]

Options:
    -h,--help       Show this help message
    -v,--version     Show version
    -s <servername>  hostname of machine, if vlan,use ip instead
    -u <username>  username [default: root]
    -p <password>  password [default: welcome1]
    --pbd   patch before deployment
"""
from docopt import docopt
import oda_patch as o_p
import oda_deploy as o_d
import oda_lib
import time
import common_fun as cf
import create_multiple_db as c_m_d
import sys


def provision_patch(host):
    if not host.is_deployed_or_not():
        o_d.oda_deploy(host)
    cf.extend_space_u01(host)
    create_db(host)
    need_to_12_vesion = ['12.1.2.8','12.1.2.8.1','12.1.2.9','12.1.2.10','12.1.2.11']
    s_v = host.system_version()
    s_v = cf.trim_version(s_v)
    if s_v in need_to_12_vesion:
        o_p.dcs_patch(host, "12.1.2.12.0")
        o_p.simple_update_server(host,"12.1.2.12.0")
        time.sleep(300)
        cf.wait_until_ping(host.hostname)
        host = oda_lib.Oda_ha(host.hostname, host.username, host.password)
        o_p.simple_update_dbhome(host, "12.1.2.12.0")

    if not host.is_latest_or_not():
        o_p.dcs_patch(host)
        o_p.server_patch(host)
        time.sleep(300)
        cf.wait_until_ping(host.hostname)
        host2 = oda_lib.Oda_ha(host.hostname, host.username, host.password)
        o_p.dbhome_patch(host2)


def create_db(host):
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes|grep -i OraDb|wc -l"
    out = host.ssh2node(cmd)
    if int(out) < 3:
        c_m_d.create_multiple_db(host)
    else:
        pass



def patch_deploy(host):
    need_to_12_vesion = ['12.1.2.8', '12.1.2.8.1', '12.1.2.9', '12.1.2.10', '12.1.2.11']
    s_v = host.system_version()
    s_v = cf.trim_version(s_v)
    if s_v in need_to_12_vesion:
        o_p.dcs_patch(host, "12.1.2.12.0")
        o_p.simple_update_server(host, "12.1.2.12.0")
        time.sleep(300)
        cf.wait_until_ping(host.hostname)
        host = oda_lib.Oda_ha(host.hostname, host.username, host.password)
    if not host.is_latest_or_not():
        o_p.dcs_patch(host)
        if not o_p.update_server(host, version = oda_lib.Oda_ha.Current_version):
            print "update server failed"
            sys.exit(0)
        time.sleep(300)
        cf.wait_until_ping(host.hostname)
        host = oda_lib.Oda_ha(host.hostname, host.username, host.password)
    if not host.is_deployed_or_not():
        o_d.oda_deploy(host)




def main(arg):
    hostname = arg['-s']
    username = arg['-u']
    password = arg['-p']
    logfile_name = 'check_deploy_patch_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    host = oda_lib.Oda_ha(hostname, username, password)
    if arg['--pbd']:
        patch_deploy(host)
    else:
        provision_patch(host)
    error = cf.logfile_close_check_error(fp, out, err,log)
    return error


if __name__ == '__main__':
    arg = docopt(__doc__)
    print arg

    main(arg)
