#!/user/bin/env python
#encoding utf-8
import oda_lib


def delete_all_dbhomes(host):
    cmd = "/opt/oracle/dcs/bin/odacli list-dbhomes|awk 'NR>3 {print $1}'"
    home_id = host.ssh2node(cmd)
    for i in home_id.split():
        if not host.delete_dbhome("-i %s" % i):
            print "delete dbhome %s failed!\n" % i


def delete_all_databases(host):
    cmd = "/opt/oracle/dcs/bin/odacli list-databases|awk 'NR>3 {print $2}'"
    db_id = host.ssh2node(cmd)
    for i in db_id.split():
        if not host.delete_database("-in %s -fd" % i):
            print "delete database %s failed!\n" % i


def main(hostname, username, password):
    logfile_name = 'check_delete_db_dbhome_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    host = oda_lib.Oda_ha(hostname,username,password)
    delete_all_databases(host)
    delete_all_dbhomes(host)
    error = cf.logfile_close_check_error(fp, out, err,log)
    return error

if __name__ == '__main__':
    main("rwsoda6m005", 'root','welcome1')