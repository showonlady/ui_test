#!/user/bin/env python
#encoding utf-8

"""
Usage:
    configure_firstnet.py -h
    configure_firstnet.py  -s <servername> -v <version> [--vm]

Options:
    -h,--help       Show this help message
    -s <servername>   hostname of machine
    -v <version>   the version you re-image to
    --vm   image to vm stack
"""


from docopt import docopt

import oda_lib
import simplejson
import sys
import common_fun as cf
import datetime
import time
import re
import image
import datetime
import random
import socket

log_dir = image.log_dir
script_dir = image.script_dir
#X7_machine = ["scaoda704c1n1", "scaoda7s005"]
netconfig = ['bonding', 'nonbonding', 'vlan']
ilomTimeout = image.ilomTimeout
ilomAdmUsr = image.ilomAdmUsr
ilomAdmPwd = image.ilomAdmPwd
ilomTimeout = image.ilomTimeout;
sshport = image.sshport
nfsip = image.nfsip
ilomUsrPwd = image.ilomUsrPwd
domain_name = "us.oracle.com"
dnsserver = "10.209.76.197"


def is_x7_or_not(hostname):
    if re.match("scaoda7", hostname):
        return 1
    else:
        return 0

def x7_network(version):
    if re.match('12.2.1.1', version):
        network = ['bonding']
    elif re.match('12.2.1.2', version):
        network = ['bonding', 'vlan']
    else:
        network = netconfig
    return network

####Need to modify in 18.3
def is_dcs(hostname, version):
    dcs = 1
    ilom = image.host_d[hostname]["ilom"]
    versions = ["12.1.2.8", "12.1.2.8.1", "12.1.2.9", "12.1.2.10", "12.1.2.11", "12.1.2.12", "12.2.1.1", "12.2.1.2", "12.2.1.3", "12.2.1.4"]
    is_x7 = is_x7_or_not(hostname)
    if len(ilom) == 2 and (not is_x7) and (version in versions):
        dcs = 0
    return dcs

def configure_firstnet_bond(hostname, imagelog, dcsflag):
    ilom = image.host_d[hostname]["ilom"]
    nodename = image.host_d[hostname]["nodename"]
    netmask = image.host_d[hostname]["netmask"]
    for i in range(len(ilom)):
        hostIp = socket.gethostbyname(nodename[i])
        cmd = script_dir + "setPublicIP.sh %s %s %s %s %s %s %s %s %s" %(ilomAdmUsr, ilom[i], ilomAdmPwd, ilomUsrPwd, hostIp, netmask, dcsflag, imagelog, ilomTimeout)
        out, err = cf.exc_cmd_new(cmd)
        if err:
            print out
            print "Set up the bonding public ip on ilom %s failed" % ilom[i]
            sys.exit(0)
    return nodename


def configure_firstnet_nonbinding(hostname, imagelog):
    ilom = image.host_d[hostname]["ilom"]
    nodename = image.host_d[hostname]["nodename"]
    netmask = image.host_d[hostname]["netmask"]
    for i in range(len(ilom)):
        hostIp = socket.gethostbyname(nodename[i])
        cmd = script_dir + "set_nonbonding_ip.sh %s %s %s %s %s %s %s %s" %(ilomAdmUsr, ilom[i], ilomAdmPwd, ilomUsrPwd, hostIp, netmask, imagelog, ilomTimeout)
        out, err = cf.exc_cmd_new(cmd)
        if err:
            print out
            print "Set up the bonding public ip on ilom %s failed" % ilom[i]
            sys.exit(0)
    return nodename


def configure_firstnet_vm(hostname, imagelog):
    ilom = image.host_d[hostname]["ilom"]
    if len(ilom) != 2:
        sys.exit(0)
    node1_dom0 = hostname[:-4] + "1"
    node2_dom0 = hostname[:-4] + "2"
    hostip1 = socket.gethostbyname(node1_dom0)
    hostip2 = socket.gethostbyname(node2_dom0)
    netmask = image.host_d[hostname]["netmask"]
    cmd = script_dir + "setdom0IP.sh %s %s %s %s %s %s %s %s %s %s %s %s" %(ilomAdmUsr, ilom[0], ilomAdmPwd, ilomUsrPwd,
                        domain_name, dnsserver,node1_dom0, node2_dom0, hostip1, hostip2, netmask, imagelog)
    out, err = cf.exc_cmd_new(cmd)
    if err:
        print out
        print "Set up the bonding public ip on ilom %s failed" % ilom[0]
        sys.exit(0)
    else:
        return [node1_dom0, node2_dom0]

def configure_firstnet_vlan(hostname, imagelog):
    if "vlan" not in image.host_d[hostname].keys():
        print "No vlan infomation for host %s" % hostname
        sys.exit(0)
    ilom = image.host_d[hostname]["ilom"]
    vlanid = image.host_d[hostname]["vlan"]["vlanid"]
    vlanIp = image.host_d[hostname]["vlan"]["vlanip"]
    vlannetmask = image.host_d[hostname]["vlan"]["vlannetmask"]
    if len(vlanIp) != len(ilom):
        print "The number of vlanip is not consistent with ilom ip!"
        sys.exit(0)
    for i in range(len(ilom)):
        cmd = script_dir + "set_vlan_ip.sh %s %s %s %s %s %s %s %s %s" % (ilomAdmUsr,
                                                                          ilom[i], ilomAdmPwd, ilomUsrPwd, vlanid, vlanIp[i], vlannetmask, imagelog, ilomTimeout)
        out, err = cf.exc_cmd_new(cmd)
        if err:
            print out
            print "Set up the VLAN public ip on ilom %s failed" % ilom[i]
            sys.exit(0)
    return vlanIp



def configure_firstnet(hostname, version, vmflag):
    log_stamp = datetime.datetime.today().strftime("%Y%m%d")
    imagelog = log_dir + "configure-firstnet_%s_%s.log" % (hostname, log_stamp)

    if vmflag:
        ips = configure_firstnet_vm(hostname, imagelog)

    else:
        x7_flag = is_x7_or_not(hostname)
        if x7_flag:
            network = random.choice(x7_network(version))
            dcsflag = 1
            if network == netconfig[2]:
                ips = configure_firstnet_vlan(hostname, imagelog)
            elif network == netconfig[1]:
                ips = configure_firstnet_nonbinding(hostname, imagelog)
            else:
                ips = configure_firstnet_bond(hostname, imagelog, dcsflag)
        else:
            dcsflag = is_dcs(hostname, version)
            ips = configure_firstnet_bond(hostname, imagelog, dcsflag)
        time.sleep(120)
        image.check_all_host_reachable(ips)
        return ips


if __name__ == "__main__":
    arg = docopt(__doc__)
    print arg
    hostname = arg['-s']
    version = arg['-v']
    vm = arg["--vm"]
    configure_firstnet(hostname, version, vm)
