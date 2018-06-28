#!/user/bin/env python
#encoding utf-8

"""
Usage:
    image.py -h
    image.py  -s <servername> -v <version> [-u <username>] [-p <password>] [--vm]

Options:
    -h,--help       Show this help message
    -s <servername>   hostname of machine
    -v <version>   the version you want to re-image to
    -u <username>   username [default: root]
    -p <password>   password [default: welcome1]
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

log_dir = "/chqin/oda_test/venv/result/"
script_dir = "/chqin/oda_test/venv/src/"
oakpassword = "welcome1"
f = open("machine.json", "r")
host_d = simplejson.load(f)
ilomAdmUsr = "root"
ilomAdmPwd = "welcome1"
ilomTimeout = 10;
factoryIlomPwd = "changeme"
sshport = '22'
nfsip = "10.214.80.5"
ilomUsrPwd = "welcome1"
copper = ["rwsoda601c1n1"]




def rwsoda315_iso(iso):
    a = re.sub('chqin', 'scratch/chqinnew', iso, 1)
    return a

def cleanup(hostname, username, password):
    if host_reachable(hostname):
        print "The host %s is reachable, will perform the cleanup!" % hostname
    else:
        print "The host %s is not reachable, could not run the cleanup!" % hostname
        return 0

    host = oda_lib.Oda_ha(hostname, username, password)
    if not host.is_dcs_or_oak():
        cmd = "perl /opt/oracle/oak/onecmd/cleanupDeploy.pl"
        result = oak_cleanup(host, cmd)
        return result
    else:
        if host.is_deployed_or_not():
            cmd = "perl /opt/oracle/oak/onecmd/cleanup.pl -griduser %s -dbuser %s" % (host.griduser(), host.racuser())
        else:
            cmd = "perl /opt/oracle/oak/onecmd/cleanup.pl"
        if host.is_ha_not():
            node2name = cf.node2_name(hostname)
            host2 = oda_lib.Oda_ha(node2name, username, password)
            result = oak_cleanup(host, cmd)
            print result
            print "Wait two minutes, and it will run cleanup on the 2nd node!"
            time.sleep(120)
            result2 = oak_cleanup(host2, cmd)
            print result2
        else:
            result = oak_cleanup(host, cmd)
            print result


def reset_ilom_password(ilom, imagelog):
    cmd = script_dir + "changeFactoryPwd.sh %s %s %s %s %s %s" % (
    ilomAdmUsr, ilom, factoryIlomPwd, ilomAdmPwd, imagelog, ilomTimeout)
    print cmd
    out, error = cf.exc_cmd_new(cmd)
    if error:
        print "Ilom %s reset of factory password failed, can't proceed reimage process!" % ilom
        sys.exit(0)
    time.sleep(60)
    cmd2 = script_dir + "resetSP.sh %s %s %s %s %s" % (ilomAdmUsr, ilom, ilomAdmPwd, imagelog, ilomTimeout)
    print cmd2
    out, error = cf.exc_cmd_new(cmd2)
    if error:
        print "ILOM %s reset failed, can't proceed reimage process" % ilom
        sys.exit(0)

def setiso(ilom, iso, imagelog):
    cmd = script_dir + "setISO.sh %s %s %s %s %s %s %s" % (ilomAdmUsr, ilom, ilomAdmPwd, iso, nfsip, imagelog, ilomTimeout)
    out, err = cf.exc_cmd_new(cmd)
    if err:
        print out
        print "ILOM %s setting up iso failed, can't proceed reimage process" % ilom
        sys.exit(0)

def vm_reset_ilom(ilom, imagelog):
    cmd = script_dir + "vm_reset_ilom.sh %s %s %s %s %s" % (ilomAdmUsr, ilom, ilomAdmPwd, imagelog, ilomTimeout)
    out, err = cf.exc_cmd_new(cmd)
    if err:
        print out
        print "Vm ILOM %s reset speed failed!" % ilom
        sys.exit(0)


def bootup(ilom, version, imagelog):
    cmd = script_dir + "checkOakFirstBoot.sh %s %s %s %s %s %s %s" %(ilomAdmUsr, ilom, ilomAdmPwd, ilomUsrPwd, version, imagelog, ilomTimeout)
    status = False
    print cmd
    for i in range(10):
        out, err = cf.exc_cmd_new(cmd)
        if err == 3:
            print "Firstboot file found on host %s!" % ilom
            status = True
            return status
        else:
            time.sleep(300)
    return status

def set_node_number(ilom, imagelog):
    for i in range(2):
        nodenum = i
        cmd = script_dir + "setNodeNumAndIPTwoJbodSystem.sh %s %s %s %s %s %s %s" %(ilomAdmUsr, ilom[i], ilomAdmPwd, ilomUsrPwd, nodenum, imagelog, ilomTimeout)
        out, err = cf.exc_cmd_new(cmd)
        if err:
            print out
            print "Set the node number on ilom %s failed" % ilom[i]
            sys.exit(0)

def configure_network_copper(ilom, imagelog):
    for i in ilom:
        cmd = script_dir + "configure_network_copper.sh %s %s %s %s %s %s" %(ilomAdmUsr, i, ilomAdmPwd, ilomUsrPwd, imagelog, ilomTimeout)
        out, err = cf.exc_cmd_new(cmd)
        if err:
            print out
            print "oakcli configure network -publicNet copper failed on %s" % i
            sys.exit(0)

def check_all_host_reachable(ilom):
    for i in ilom:
        if not host_reachable(i):
            print "The host %s was not reachable!" % i
            sys.exit(0)
        else:
            print "The host %s was reachable." % i

def check_all_host_port_reachable(ilom):
    for i in ilom:
        if not host_reachable(i):
            print "The ilom %s was not reachable after reset sp,can't proceed reimage process!" % i
            sys.exit(0)
        if not port_reachable(i):
            print "The ssh port on node %s not reachable, can't proceed reimage process" % i


def image(hostname, version, vmflag):
    log_stamp = datetime.datetime.today().strftime("%Y%m%d")
    imagelog = log_dir + "image_%s_%s.log" % (hostname, log_stamp)
    ilom = host_d[hostname]["ilom"]
    ####Check all the ilom are reachable
    check_all_host_reachable(ilom)

    ###reset ilom password and reset host ilom
    for i in ilom:
        reset_ilom_password(i, imagelog)

    ###check for ilom reachability post reset sp
    check_all_host_port_reachable(ilom)

    ####set iso
    time.sleep(240)
    iso = generate_iso(hostname, version, vmflag)
    print iso
    for i in ilom:
        setiso(i, iso, imagelog)

    ######Wait for about half an hour
    time.sleep(1800)
    ####If the host is vm, we need to reset the pending speed to 9600
    if vmflag:
        for i in ilom:
            vm_reset_ilom(i, imagelog)

    ####Check if the host is boot up
    for i in ilom:
        status = bootup(i, version,imagelog)
        if not status:
            print "Could not find the first boot file on host %s" % i

    ######If the system is two jbod system, we need to set the node num
    if host_d[hostname]["jbod"] == 2:
        set_node_number(ilom, imagelog)
        time.sleep(300)
    ####For rwsoda601c1n1, we need to run "oakcli configure network -publicNet copper"
    if hostname in copper:
        configure_network_copper(ilom, imagelog)
        ##Wait the host to boot up
        time.sleep(300)




def generate_iso(hostname, version, vmflag):
    iso1 = getiso(hostname, version, vmflag)
    if not iso1:
        sys.exit(0)
    iso = rwsoda315_iso(iso1)
    return iso


def getiso(hostname, version, vmflag):
    flag = 0
    ver = cf.trim_version(version)
    loc = "/chqin/ODA%s/" % ver
    oliteIso1 = "singlenode_*iso";
    oliteIso2 = "odalite-os-image*iso";
    odaIso1 = "multinode_*iso";
    odaIso2 = "OAKFactoryImage*iso";
    vmiso = "OakOvm_*.iso"

    if vmflag:
        cmd = 'ls %s' %(loc + vmiso)
        out, err = cf.exc_cmd_new(cmd)
        if err:
            print "Could not find the iso: %s" % (loc + vmiso)
            return flag
        else:
            print out
            return out.strip()

    if len(host_d[hostname]["ilom"]) == 2:
        cmd = 'ls %s' %(loc + odaIso1)
        out, err = cf.exc_cmd_new(cmd)
        if err:
            cmd1 = 'ls %s' %(loc + odaIso2)
            out, err = cf.exc_cmd_new(cmd1)
            if err:
                print "Could not find the iso: %s" % (loc + odaIso2)
                return flag
            else:
                print out
                return out.strip()
        else:
            print out
            return out.strip()

    if len(host_d[hostname]["ilom"]) == 1:
        cmd = 'ls %s' %(loc + oliteIso1)
        out, err = cf.exc_cmd_new(cmd)
        if err:
            cmd1 = 'ls %s' %(loc + oliteIso2)
            out, err = cf.exc_cmd_new(cmd1)
            if err:
                print "Could not find the iso: %s" % (loc + oliteIso2)
                return flag
            else:
                print out
                return out.strip()
        else:
            print out
            return out.strip()



def port_reachable(hostname, sshport = sshport):
    result = 0
    cmd = "nc -vz %s %s" %(hostname, sshport)
    for i in range(5):
        out, err = cf.exc_cmd_new(cmd)
        if not err:
            result = 1
            print "Ilom %s port %s reachable" %(hostname, sshport)
            return result
        else:
            time.sleep(60)
    return result

def host_reachable(hostname):
    result = 0
    cmd = "ping -c 3 %s | grep '3 received' | wc -l" % hostname
    for i in range(5):
        out,err = cf.exc_cmd_new(cmd)
        if err:
            print err
            return result
        else:
            if int(out):
                result = 1
                return result
            else:
                time.sleep(60)
    return result












def oak_cleanup(host, cmd):
    print cmd
    sys.stdout.flush()
    stdin, stdout, stderr = host.ssh.exec_command(cmd)
    if not host.is_dcs_or_oak():
        stdin.write("%s\n" % oakpassword)
        stdin.write("%s\n" % oakpassword)
    stdin.write("%s\n" % 'yes')
    result = stdout.read().strip()
    errormsg = stderr.read().strip()
    return result + errormsg



    


if __name__ == '__main__':
    arg = docopt(__doc__)
    print arg
    hostname = arg['-s']
    version = arg['-v']
    password = arg['-p']
    username = arg['-u']
    vm = arg["--vm"]
    cleanup(hostname, username, password)
    time.sleep(300)
    image(hostname, version, vm)




