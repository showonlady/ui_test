#!/user/bin/env python
#encoding utf-8

import oda_lib
import random
import common_fun as cf
import os
import re
from sys import argv
import sys
import time

sql_file = 'sql_check.sh'
delete_file_name = 'delete_file.sh'
backupreport = 'backupreport.br'
dbstatus = 'dbstatus_check.sh'
scn_sql = "select current_scn SCN from v\$database";
pitr_sql = "select to_char(sysdate, 'mm/dd/yyyy hh24:mi:ss')PITR from dual";
spfile_sql = "select value from v\$parameter where name ='spfile'";
control_sql = "select name from v\$controlfile";
datafile_sql = "select name from v\$datafile";
remote_dir = '/tmp'
bkpassword = "WElcome12#_"
#dbname = argv[1]

tag = cf.generate_string(cf.string2,8)


def randomget_dbname(host):
    cmd = "/opt/oracle/dcs/bin/odacli list-databases|grep Configured|awk '{print $2}'"
    result, error = host.ssh2node_job(cmd)
    if not error:
        dbname = random.choice(result.split())
        return dbname
    else:
        dbname = create_new_db(host)
        return dbname



def create_new_db(host):
    if host.create_database("-hm WElcome12__ -n testxx "):
        return "testxx"
    else:
        return 0
    



def backup_disk(host):
    op = ['-cr -w 1','-no-cr -w 7','-cr -w 14']
    name = cf.generate_string(cf.string1, 8)
    for i in range(0,len(op)):
        bk_name = name + str(i)
        bk_op = '-d Disk '+ '-n %s ' % bk_name + op[i]
        if not host.create_backupconfig(bk_op):
            print "create backup config %s fail!\n" % bk_name
            return 0
        updatedb_op = "-in %s -bin %s" %(dbname, bk_name)
        if not host.update_database(updatedb_op):
            print "update db %s with backup config %s fail!\n" % (dbname, bk_name)
            return 0

        if i == 0:
            tag1 = cf.generate_string(cf.string2, 8)
            create_bk_op_n = ["-bt Longterm -in %s -k 1 -t test" % dbname, "-c TdeWallet -in %s" % dbname,
                          "-bt Regular-L0 -in %s -k 1" % dbname, "-bt ArchiveLog -in %s -t %s" % (dbname, tag1)]
            for j in range(0, len(create_bk_op_n)):
                if host.create_backup(create_bk_op_n[j]) and j != 3:
                    print "Nigtive case for backup fail! %s \n" % create_bk_op_n[j]
        host.disable_auto_backup()
        if not recover_test(host):
            sys.exit(0)

def backup_oss(host):
    oss_name = cf.generate_string(cf.string2, 8)
    print oss_name
    oss_result = host.create_objectstoreswift(oss_name)
    if not oss_result :
        return 0
    #op_oss = "-d ObjectStore -c chqin -on %s " % oss_name
    op_oss = "-d ObjectStore -c 'oda-oss' -on %s " % oss_name
    op = ['-cr -w 1','-no-cr -w 15','-cr -w 30']
    name = cf.generate_string(cf.string1, 8)
    for i in range(len(op)):
        bk_name = name + str(i)
        bk_op = '-n %s ' % bk_name + op_oss + op[i]
        if not host.create_backupconfig(bk_op):
            print "create backup config %s fail!\n" % bk_name
            return 0
        updatedb_op = "-in %s -bin %s -hbp %s" %(dbname, bk_name,bkpassword)
        if not host.update_database(updatedb_op):
            print "update db %s with backup config %s fail!\n" % (dbname, bk_name)
            return 0

        if i == 0:
            tag1 = cf.generate_string(cf.string2, 8)
            create_bk_op_n = ["-bt Longterm -in %s -k 1" % dbname, "-c TdeWallet -in %s" % dbname,
                          "-bt Regular-L0 -in %s -k 1" % dbname, "-bt ArchiveLog -in %s -t %s" % (dbname, tag1)]
            for j in range(0, len(create_bk_op_n)):
                if host.create_backup(create_bk_op_n[j]) and j != 3:
                    print "Nigtive case for backup fail! %s \n" % create_bk_op_n[j]
        host.disable_auto_backup()
        time.sleep(120)
        if not recover_test_oss(host):
            sys.exit(0)


def create_bk_op_oss():
    i = random.choice(range(4))
    if i == 0:
        a = "-bt Regular-L0 -in %s " % dbname
    elif i == 1:
        a = "-bt Regular-L1 -c Database -in %s" % dbname
    elif i == 2:
        tag = cf.generate_string(cf.string2,8)
        a = "-bt Longterm -in %s -k 1 -t %s" % (dbname, tag)
    elif i == 3:
        tag = cf.generate_string(cf.string2,8)
        a = "-bt Regular-L1 -in %s -t %s" % (dbname, tag)
    return a



def recover_test_oss(host):
    op = create_bk_op_oss()
    if not host.create_backup(op):
        print "create backup fail %s\n" % op
        return 0
    allfile_loss(host)
    if not host.recover_database("-in %s -t Latest -hp %s" % (dbname, bkpassword)):
        print "recover database with latest fail %s\n" % dbname
        return 0
    check_dbstatus(host)

    op = create_bk_op_oss()
    if not host.create_backup(op):
        print "create backup fail %s\n" % op
        return 0
    s = current_scn(host)
    sp_control_loss(host)
    if not host.recover_database("-in %s -t SCN -s %s -hp %s" % (dbname, s, bkpassword)):
        print "recover database with SCN fail! %s\n" % dbname
        return 0
    check_dbstatus(host)

    op = create_bk_op_oss()
    if not host.create_backup(op):
        print "create backup fail! %s\n" % op
        return 0
    p = current_pitr(host)
    control_datafile_loss(host)
    if not host.recover_database("-in %s -t PITR -r %s -hp %s" % (dbname, p,bkpassword)):
        print "recover database with PIRT fail! %s\n" % dbname
        return 0
    check_dbstatus(host)
    op = create_bk_op_oss()
    if not host.create_backup(op):
        print "create backup fail %s\n" % op
        return 0
    generate_backupreport(host)
    sp_datafile_loss(host)
    br = os.path.join(remote_dir, os.path.basename(backupreport))
    if not host.recover_database("-in %s -br %s -hp %s" % (dbname,br,bkpassword)):
        print "recover database with backupreport fail! %s\n" % dbname
        return 0
    check_dbstatus(host)
    return 1


def recover_test(host):
    create_bk_op_disk = ["-bt Regular-L0 -in %s " % dbname, "-bt Regular-L1 -c Database -in %s" % dbname,
                         "-bt Regular-L0 -in %s -t %s" % (dbname, tag), "-bt Regular-L1 -in %s -t %s" % (dbname, tag)]
    op = random.choice(create_bk_op_disk)
    if not host.create_backup(op):
        print "create backup fail %s\n" % op
        return 0
    allfile_loss(host)
    if not host.recover_database("-in %s -t Latest" % dbname):
        print "recover database with latest fail %s\n" % dbname
        return 0
    check_dbstatus(host)

    op = random.choice(create_bk_op_disk)
    if not host.create_backup(op):
        print "create backup fail %s\n" % op
        return 0
    s = current_scn(host)
    sp_control_loss(host)
    if not host.recover_database("-in %s -t SCN -s %s" % (dbname, s)):
        print "recover database with SCN fail! %s\n" % dbname
        return 0
    check_dbstatus(host)

    op = random.choice(create_bk_op_disk)
    if not host.create_backup(op):
        print "create backup fail! %s\n" % op
        return 0
    p = current_pitr(host)
    control_datafile_loss(host)
    if not host.recover_database("-in %s -t PITR -r %s" % (dbname, p)):
        print "recover database with PIRT fail! %s\n" % dbname
        return 0
    check_dbstatus(host)
    op = random.choice(create_bk_op_disk)
    if not host.create_backup(op):
        print "create backup fail %s\n" % op
        return 0
    generate_backupreport(host)
    sp_datafile_loss(host)
    br = os.path.join(remote_dir, os.path.basename(backupreport))
    if not host.recover_database("-in %s -br %s" % (dbname,br)):
        print "recover database with backupreport fail! %s\n" % dbname
        return 0
    check_dbstatus(host)
    return 1


def generate_backupreport(host):
    cmd1 = "/opt/oracle/dcs/bin/odacli list-backupreports|egrep -i 'Regular-|Long'|tail -n 1|awk '{print $1}'"
    bkreport_id = host.ssh2node(cmd1)
    bkreport = host.describe_backupreport("-i %s" %bkreport_id)
    fp = open(backupreport, 'w')
    fp.write(bkreport)
    fp.close()
    remote_file = os.path.join(remote_dir, os.path.basename(backupreport))
    host.scp2node(backupreport, remote_file)


def check_dbstatus(host):
    oracle_home = host.dbnametodbhome(dbname)
    fp = open(dbstatus, 'w')
    fp.write("#!/bin/bash\n")
    fp.write("export ORACLE_HOME=%s\n" % oracle_home)
    fp.write("%s/bin/srvctl status database -d %s;\n" % (oracle_home, dbname))
    fp.close()
    remote_file = os.path.join(remote_dir, os.path.basename(dbstatus))
    host.scp2node(dbstatus, remote_file)
    racuser = host.racuser()
    racgroup = host.racgroup()
    cmd1 = "/bin/chown %s:%s %s" % (racuser, racgroup, remote_file)
    cmd2 = "/bin/chmod +x %s" % remote_file
    cmd3 = "/bin/su - %s -c %s" % (racuser, remote_file)
    host.ssh2node(cmd1)
    host.ssh2node(cmd2)
    result = host.ssh2node(cmd3) + '\n'
    print result


def current_scn(host):
    result = sql_result(host,scn_sql)
    result = result.strip()
    x = result.split('\n')
    y = x[-1].strip()
    return y


def current_pitr(host):
    result = sql_result(host,pitr_sql)
    result = result.strip()
    x = result.split('\n')
    y = x[-1].strip()
    return y


def datafile_loss(host):
    file = sql_result(host, datafile_sql)
    delete_file(host,file)

def controlfile_loss(host):
    file = sql_result(host, control_sql)
    delete_file(host,file)

def spfile_loss(host):
    file = sql_result(host, spfile_sql)
    delete_file(host,file)

def allfile_loss(host):
    datafile = sql_result(host, datafile_sql)
    controlfile = sql_result(host, control_sql)
    spfile = sql_result(host, spfile_sql)
    file = datafile + controlfile + spfile
    print file
    delete_file(host,file)

def sp_control_loss(host):
    controlfile = sql_result(host, control_sql)
    spfile = sql_result(host, spfile_sql)
    file = controlfile + spfile
    delete_file(host, file)

def sp_datafile_loss(host):
    datafile = sql_result(host, datafile_sql)
    spfile = sql_result(host, spfile_sql)
    file = datafile + spfile
    delete_file(host, file)

def control_datafile_loss(host):
    datafile = sql_result(host, datafile_sql)
    controlfile = sql_result(host, control_sql)
    file = datafile + controlfile
    delete_file(host,file)

def delete_file(host, x):
    if db_on_asm_acfs(host):
        delete_asm_file(host,x)
    else:
        delete_acfs_file(host,x)


def sql_result(host, sql):
    sql_script(host,sql)
    remote_file = os.path.join(remote_dir, os.path.basename(sql_file))
    host.scp2node(sql_file, remote_file)
    racuser = host.racuser()
    racgroup = host.racgroup()
    cmd1 = "/bin/chown %s:%s %s" % (racuser, racgroup, remote_file)
    cmd2 = "/bin/chmod +x %s" % remote_file
    cmd3 = "/bin/su - %s -c %s" % (racuser, remote_file)
    host.ssh2node(cmd1)
    host.ssh2node(cmd2)
    result = host.ssh2node(cmd3) + '\n'
    return result

def sql_script(host,sql):
    oracle_sid = host.dbnametoinstance(dbname)
    oracle_home = host.dbnametodbhome(dbname)
    fp = open(sql_file, 'w')
    fp.write("#!/bin/bash\n")
    fp.write("export ORACLE_SID=%s\n" % oracle_sid)
    fp.write("export ORACLE_HOME=%s\n" % oracle_home)
    fp.write("%s/bin/sqlplus -S -L / as sysdba <<EOF\n" % oracle_home)
    fp.write("%s;\n" % sql)
    fp.write("EOF\n")
    fp.close()

#asm --1
#acfs --0
def db_on_asm_acfs(host):
    d = host.describe_database("-in %s" % dbname)
    if d["dbStorage"] == 'ASM':
        return 1
    else:
        return 0


def delete_asm_file(host,x):
    fp = open(delete_file_name, 'w')
    y = x.split()
    for i in y:
        if re.search("^\+", i):
            i.strip('\n')
            fp.write("asmcmd rm -rf %s\n" % i)
    fp.close()
    remote_file = os.path.join(remote_dir, os.path.basename(delete_file_name))
    host.scp2node(delete_file_name, remote_file)
    griduser = host.griduser()
    gridgroup = host.gridgroup()
    cmd1 = "/bin/chown %s:%s %s" % (griduser, gridgroup, remote_file)
    cmd2 = "/bin/chmod +x %s" % remote_file
    cmd3 = "/bin/su - %s -c %s" % (griduser, remote_file)
    host.ssh2node(cmd1)
    host.ssh2node(cmd2)
    sql_result(host,"shutdown immediate")
    host.ssh2node(cmd3)
    sql_result(host, "startup")

def delete_acfs_file(host, x):
    fp = open(delete_file_name, 'w')
    y = x.split()
    for i in y:
        if re.search("^/", i):
            i.strip('\n')
            fp.write("rm -rf %s\n" % i)
    fp.close()
    remote_file = os.path.join(remote_dir, os.path.basename(delete_file_name))
    host.scp2node(delete_file_name, remote_file)
    griduser = host.griduser()
    print griduser
    gridgroup = host.gridgroup()
    print gridgroup
    cmd1 = "/bin/chown %s:%s %s" % (griduser, gridgroup, remote_file)
    cmd2 = "/bin/chmod +x %s" % remote_file
    cmd3 = "/bin/su - %s -c %s" % (griduser, remote_file)
    host.ssh2node(cmd1)
    host.ssh2node(cmd2)
    host.ssh2node(cmd3)



def main(hostname, username, password):
    logfile_name = 'check_back_recovery_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    host = oda_lib.Oda_ha(hostname, username, password)
    global dbname
    dbname = randomget_dbname(host)
    print dbname
    if dbname:
        #backup_disk(host)
        backup_oss(host)
    else:
        print "Fail to get the dbname!"
    error = cf.logfile_close_check_error(fp, out, err,log)
    return error

if __name__ == '__main__':
    main("scaoda704c1n1", 'root','welcome1')