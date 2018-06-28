#!/user/bin/env python
#coding utf-8

import oda_lib
import random
import common_fun as cf
import sys


def positive_case(host,num):
    cpucores = range(2,num+2,2)
    print cpucores
    for i in cpucores:
        op = "-c %s" % i
        if not host.update_cpucore(op):
            print "update cpucore to %s fail!" % i
        else:
            print "update cpucore to %s!" % i
            if not check_cpucore(host,i):
                print "check failed! %s" % i
                sys.exit(0)


def negative_case(host):
    cpucores = ['0','3','-1','5.5','40','a', '2']
    for i in cpucores:
        op = "-c %s" % i
        if host.update_cpucore(op):
            print "negative case fail!"


def positive_case2(host, num):
    cpucores = [4, 8, 16, 2, num]
    for i in cpucores:
        op = "-c %s -f" % i
        if not host.update_cpucore(op):
            print "update cpucore to %s fail!" % i
        else:
            print "update cpucore to %s!" % i
            if not check_cpucore(host,i):
                print "check failed! %s" % i
                sys.exit(0)



def check_cpucore(host, i):
    num1 = host.decribe_cpucore()[0]['cpuCores']
    cmd1 = "lscpu|grep Core|awk '{print $4}'"
    cmd2 = "lscpu|grep Socket|awk '{print $2}'"
    core = host.ssh2node(cmd1)
    socket = host.ssh2node(cmd2)
    num2 = int(core) * int(socket)
    if int(num1) == num2 and i == num2:
        return 1
    else:
        return 0


def main(hostname, username, password):
    logfile_name = 'check_cpucore_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    host = oda_lib.Oda_ha(hostname, username, password)
    cpucore_org = host.decribe_cpucore()[0]['cpuCores']
    positive_case(host, int(cpucore_org))
    negative_case(host)
    positive_case2(host, int(cpucore_org))
    error = cf.logfile_close_check_error(fp, out, err,log)
    return error

if __name__ == '__main__':
    main("10.31.129.245", 'root','welcome1')



