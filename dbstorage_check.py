#!/user/bin/env python
#coding utf-8

import common_fun as cf
import random
import re
import oda_lib
import os

def dbstorage_asm_create(host):

    size = ['-s 100 ','-s 200 ']

    for i in size:
        dbname = cf.generate_string(cf.string1, 8)
        op = "-n %s -r ASM %s" % (dbname,i)
        if random.choice(['True','False']):
            dbuniqname = cf.generate_string(cf.string2, 20)
            op += '-u %s ' % dbuniqname
        if host.is_flash():
            flash = random.choice(['-f ', '-no-f '])
            op += flash
        if not host.create_dbstorage(op):
            print "create dbstorage failed! %s" % op
        else:
            dbstorage_id = host.ssh2node("/opt/oracle/dcs/bin/odacli list-dbstorages|tail -n 1|awk '{print $1}'")
            if not check_asm_dbstorage(host,op,dbstorage_id):
                print "describe dbstorage failed! %s" % op
            else:
                if not host.delete_dbstorage("-i %s" % dbstorage_id):
                    print "delete dbstorage failed! %s" % op



def check_asm_dbstorage(host,op,dbstorage_id):
    print dbstorage_id
    a = host.describe_dbstorage("-i %s" % dbstorage_id)

    list = [a['name'], a['dbStorage'],a['recoDestination'],
            a['redoDestination'],a['dataDestination'],
            a['databaseUniqueName'],a['state']['status']]

    n_s = re.search('-n\s+(\S+)\s+-r\s+(\S+)',op).groups()
    list1 = [n_s[0],n_s[1], 'RECO']
    if host.is_ha_not():
        list1.append('REDO')
    else:
        list1.append('RECO')
    f_n = re.search('( -f)', op)
    if f_n:
        list1.append('FLASH')
    else:
        list1.append('DATA')
    u_n = re.search('-u\s+(\S+)',op)
    if u_n:
        list1.append(u_n.group(1))
    else:
        list1.append(n_s[0])
    list1.append('CONFIGURED')
    if list == list1:
        return 1
    else:
        print list1
        return 0



def dbstorage_acfs_create(host):
    size = ['-s 100 ', '-s 200 ']

    for i in size:
        dbname = cf.generate_string(cf.string1, 8)
        op = "-n %s -r ACFS %s" % (dbname, i)
        if random.choice(['True', 'False']):
            dbuniqname = cf.generate_string(cf.string2, 20)
            op += '-u %s ' % dbuniqname
        if host.is_flash():
            flash = random.choice(['-f ', '-no-f '])
            op += flash
        if not host.create_dbstorage(op):
            print "create dbstorage failed! %s" % op
        else:
            dbstorage_id = host.ssh2node("/opt/oracle/dcs/bin/odacli list-dbstorages|tail -n 1|awk '{print $1}'")
            if not check_acfs_dbstorage(host, op, dbstorage_id):
                print "describe dbstorage failed! %s" % op
            else:
                if not host.delete_dbstorage("-i %s" % dbstorage_id):
                    print "delete dbstorage failed! %s" % op

def check_acfs_dbstorage(host,op,dbstorage_id):
    print dbstorage_id
    a = host.describe_dbstorage("-i %s" % dbstorage_id)

    list = [a['name'], a['dbStorage'],a['recoDestination'],
            a['redoDestination'],a['dataDestination'],
            a['databaseUniqueName'],a['state']['status']]

    n_s = re.search('-n\s+(\S+)\s+-r\s+(\S+)',op).groups()
    oracle_user = host.racuser()
    reco = "/u03/app/%s/fast_recovery_area/" % oracle_user
    list1 = [n_s[0],n_s[1],reco]
    if host.is_ha_not():
        redo = "/u04/app/%s/redo/" % oracle_user
    else:
        redo = "/u03/app/%s/redo/" % oracle_user
    list1.append(redo)
    u_n = re.search('-u\s+(\S+)',op)
    if u_n:
        uniquename = u_n.group(1)
    else:
        uniquename = n_s[0]
    f_n = re.search(' -f', op)
    if f_n:
        data = "/u02/app/%s/flashdata/%s" %(oracle_user,uniquename)
    else:
        data = "/u02/app/%s/oradata/%s" % (oracle_user,uniquename)

    list1.append(data)
    list1.append(uniquename)
    list1.append('CONFIGURED')
    if list != list1:
        print list1
        return 0

    s = re.search('-s\s+(\S+)',op)
    if s:
        size = s.group(1)
    else:
        size = '100'
    df = host.ssh2node("df -h %s" % data)
    data_size = df.split()[8]
    if path_exist_or_not(host,data) and path_exist_or_not(host, reco) and path_exist_or_not(host, redo) and data_size[:-1] == size:
        return 1
    else:
        return 0


def path_exist_or_not(host, a):
    cmd = "ls %s" % a
    result = host.ssh2node(cmd)
    if re.search("No such", result):
        return 0
    else:
        return 1


def main(hostname, username, password):
    logfile_name = 'check_create_dbstorage_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    #out, err = sys.stdout, sys.stderr
    #fp = open(logfile_name_stamp, 'a')
    #sys.stdout, sys.stderr = fp, fp

    host = oda_lib.Oda_ha(hostname, username, password)
    dbstorage_asm_create(host)
    dbstorage_acfs_create(host)
    error = cf.logfile_close_check_error(fp, out, err,log)
    return error




if __name__ == '__main__':
    main("scaoda704c1n1",'root','welcome1')