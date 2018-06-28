#!/usr/bin/env python
# -*- coding: utf-8 -*-

import paramiko
import os
import datetime
import difflib
import re
import time
import string
import random
import sys
import subprocess
import oda_lib

log_stamp = datetime.datetime.today().strftime("%Y%m%d")
log_dir = os.path.join(os.getcwd(), 'result')


string1 = string.ascii_letters + string.digits
string2 = string.ascii_letters + string.digits + "_"
def generate_string(source, length):
    len1 = random.randint(1, length)
    cha = random.choice(string.ascii_letters)
    chb = ''.join(random.sample(source, len1-1))
    return cha+chb

def openfile(filename):
    out, err = sys.stdout, sys.stderr
    fp = open(filename, 'a')
    sys.stdout, sys.stderr = fp, fp
    return fp, out, err

def closefile(fp, out, error):
    fp.close()
    sys.stdout, sys.stderr = out, error




"""
class logfile(object):
    out, err = sys.stdout, sys.stderr
    def __init__(self, name):
        self.name = name
        self.out, self.err = sys.stdout, sys.stderr

    def openfile(self):
        fp = open(self.name, 'w')
        sys.stdout = fp
        sys.stderr = fp
        return fp

    def closefile(self, fp):
        fp.close()
        sys.stdout, sys.stderr= self.out, self.err

"""

def logfile_name_gen_open(logfile_name):
    log_stamp = datetime.datetime.today().strftime("%Y%m%d")
    logfile_name_stamp = logfile_name+ '_' + log_stamp
    log = os.path.join(log_dir, logfile_name_stamp)
    fp, out, err = openfile(log)
    return fp, out, err,log

def logfile_close(fp, out, err):
    closefile(fp, out, err)

def logfile_close_check_error(fp, out, err,log):
    closefile(fp, out, err)
    error = check_log(log)
    return error

def check_log(log_name):
    #cmd = "egrep -B1 -i 'DCS-|fail|error|exception|warn|No such file' %s" % log_name
    cmd = "egrep -B1 -i 'fail' %s" % log_name
    output = exc_cmd(cmd)
    log_error = os.path.join(log_dir,'log_error_%s' % log_stamp)
    fp = open(log_error, 'a')
    fp.write("\n\n%s === Summary: Here is the errors:\n\n" % log_name)
    if not output:
        fp.write("No error!\n")
        fp.close()
        return 1
    else:
        fp.write(output)
        fp.close()
        return 0

def exc_cmd(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdout, stderr) = p.communicate()
    return stdout + stderr


def exc_cmd_new(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdout, stderr) = p.communicate()
    recode = p.returncode
    return stdout + stderr, recode


def trim_version(x):
    while x[-1] == '0':
        x = x[:-2]
    return x

def ping_host(hostname):
    cmd = "ping -c 3 %s | grep '3 received' | wc -l" % hostname
    result = int(exc_cmd(cmd))
    return result

def wait_until_ping(hostname):
    while(not ping_host(hostname)):
        time.sleep(10)
    time.sleep(300)

def extend_space_u01(host):
    host.extend_u01()
    if host.is_ha_not():
        node2 = node2_name(host.hostname)
        host2 = oda_lib.Oda_ha(node2, host.username, host.password)
        host2.extend_u01()




def node2_name(a):
    if re.search('com', a):
        name = a.split('.',1)
        n1 = name[0]
        b = n1[:-1] + str(int(n1[-1]) + 1) + '.' + name[1]
    else:
        b = a[:-1] + str(int(a[-1]) + 1)
    return b