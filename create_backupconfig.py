import oda_lib
import random
import string
import common_fun as cf



def describe_check(d,dest, i, j):
    if d['backupDestination'] == dest and d['recoveryWindow'] == j:
        if i == '-cr ' and d['crosscheckEnabled'] == True or i == '-no-cr ' and d['crosscheckEnabled'] == False:
            return 1
        else:
            return 0

def delete_backupconfig(host, name, id):
    if random.choice([True, False]):
        op = "-in %s" % name
    else:
        op = "-i %s" % id
    return host.delete_backupconfig(op)



def create_bkc_disk(host):
    op = "-d Disk "
    for i in ['-cr ', '-no-cr ']:
        for j in ['0','-1','15']:
            bkname = cf.generate_string(cf.string1, 8)
            op1 = op + i + '-w %s -n %s' %(j, bkname)
            if host.create_backupconfig(op1):
                print "Nigtive case for backupconfig fail! %s \n" % op1

    for i in ['-cr ', '-no-cr ']:
        for j in ['1','7','14']:
            bkname = cf.generate_string(cf.string1, 8)
            op2 = op + i + '-w %s -n %s' %(j, bkname)
            if not host.create_backupconfig(op2):
                print "Create backupconfig fail! %s \n" % op2
            else:
                describe_info = host.describe_backupconfig("-in %s" % bkname)
                bkid = describe_info['id']
                if not describe_check(describe_info,'Disk', i, j):
                    print "describe backupconfig %s fail!" % bkname
                else:
                    if not delete_backupconfig(host, bkname, bkid):
                        print "delete backupconfig %s fail!\n" % bkname


def create_bkc_oss(host):
    oss_name = cf.generate_string(cf.string2, 8)
    print oss_name
    oss_result = host.create_objectstoreswift(oss_name)
    if not oss_result :
        return 0

    #op = "-d ObjectStore -c chqin -on %s " % oss_name
    op = "-d ObjectStore -c oda-oss -on %s " % oss_name

    for i in ['-cr ', '-no-cr ']:
        for j in ['0','-1','31']:
            bkname = cf.generate_string(cf.string1, 8)
            op1 = op + i + '-w %s -n %s' %(j, bkname)
            if host.create_backupconfig(op1):
                print "Nigtive case for backupconfig fail! %s \n" % op1

    for i in ['-cr ', '-no-cr ']:
        for j in ['1','15','30']:
            bkname = cf.generate_string(cf.string1, 8)
            op2 = op + i + '-w %s -n %s' %(j, bkname)
            if not host.create_backupconfig(op2):
                print "Create backupconfig fail! %s \n" % op2
            else:
                describe_info = host.describe_backupconfig("-in %s" % bkname)
                bkid = describe_info['id']
                if not describe_check(describe_info, 'ObjectStore', i, j):
                    print "describe backupconfig %s fail!" % bkname
                else:
                    if not delete_backupconfig(host, bkname, bkid):
                        print "delete backupconfig %s fail!\n" % bkname

def create_bkc_none(host):
    op = "-d None "
    bkname = cf.generate_string(cf.string1, 8)
    op = op + '-n %s' % bkname
    if not host.create_backupconfig(op):
        print "Create backupconfig fail! %s \n" % op
    else:
        describe_info = host.describe_backupconfig("-in %s" % bkname)
        bkid = describe_info['id']
        if describe_info['backupDestination'] != 'NONE':
            print "describe backupconfig %s fail!" % bkname
        else:
            if not delete_backupconfig(host, bkname, bkid):
                print "delete backupconfig %s fail!\n" % bkname


  
def main(hostname, username, password):
    logfile_name = 'check_create_backupconfig_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    #out, err = sys.stdout, sys.stderr
    #fp = open(logfile_name_stamp, 'a')
    #sys.stdout, sys.stderr = fp, fp

    host = oda_lib.Oda_ha(hostname, username, password)
    #create_bkc_disk(host)
    create_bkc_oss(host)
    #create_bkc_none(host)
    error = cf.logfile_close_check_error(fp, out, err,log)
    return error

if __name__ == '__main__':
    main("rwsoda6f004", 'root','welcome1')