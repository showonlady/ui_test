#!/user/bin/env python


"""
Usage:
    a.py -h
    a.py -s <servername> [-u <username>] [-p <password>] [-o <filename>]

Options:
    -h,--help       Show this help message
    -v,--version     Show version
    -s <servername>  hostname of machine, if vlan,use ip instead
    -u <username>  username [default: root]
    -p <password>  password [default: welcome1]
    -o <jsonfile>  json file path [default: jsonfile]
"""

import paramiko
import oda_lib_oak
from docopt import docopt
import time
import datetime
import common_fun as cf
import sys

def a(hostname):
    if cf.ping_host(hostname):
        print "*********"
    else:
        print "fail"





if __name__ == '__main__':
    #logfile_name = 'tesrssssss.log'
    #fp, out, err, log = cf.logfile_name_gen_open(logfile_name)
    #while(True):

     #   print  datetime.datetime.now()
      #  sys.stdout.flush()

    #cf.logfile_close_check_error(fp, out, err, log)
    a("rwsoda6011-c")

