#!/user/bin/env python
#coding utf-8

import re
import os
import paramiko
import traceback
import time
import simplejson
import common_fun as cf
import sys

class Oda_ha(object):
    Current_version = "12.2.1.4.0"
    ODACLI = "/opt/oracle/dcs/bin/odacli "
    def __init__(self, hostname, username, password):
        self.hostname = hostname
        self.username = username
        self.password = password
        self.newpassword = "WElcome12_-"
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            self.ssh.connect(hostname=self.hostname, port=22, username=self.username, password=self.password)
        except Exception as e:
            self.ssh.connect(hostname=self.hostname, port=22, username=self.username, password=self.newpassword)
        try:
            self.transport = paramiko.Transport((self.hostname, 22))
            self.transport.connect(username=self.username, password=self.password)
        except Exception as e:
            self.transport = paramiko.Transport((self.hostname, 22))
            self.transport.connect(username=self.username, password=self.newpassword)

    def is_dcs_or_oak(self):
        cmd = "rpm -qa|grep dcs"
        result = self.ssh2node(cmd)
        if result:
            return 1
        else:
            return 0


    def is_deployed_or_not(self):
        cmd = "ps -ef|grep 'init.ohasd' |grep -v grep"
        result = self.ssh2node(cmd)
        if result:
            return 1
        else:
            return 0

    def is_x6_or_x7(self):
        cmd = "cat /proc/cmdline|grep X6"
        result = self.ssh2node(cmd)
        if result:
            return 1
        else:
            return 0



            
    def is_latest_or_not(self):
        s_v = self.system_version()
        a = cf.trim_version(s_v)
        b = cf.trim_version(Oda_ha.Current_version)
        if a == b:
            return 1
        else:
            return 0


    def system_version(self):
        cmd = "cat /opt/oracle/oak/pkgrepos/System/VERSION"
        result = self.ssh2node(cmd)
        v = result.split("=")[1]
        return v

    
    
    def ssh2node(self, cmd):
        #print cmd
        stdin, stdout, stderr = self.ssh.exec_command(cmd)
        result = stdout.read().strip()
        errormsg = stderr.read().strip()
        # self.ssh.close()
        return result + errormsg

    def ssh2node_input(self, cmd):
        print cmd
        sys.stdout.flush()
        stdin, stdout, stderr = self.ssh.exec_command(cmd)
        stdin.write("%s\n" % self.newpassword)
        result = stdout.read().strip()
        errormsg = stderr.read().strip()
        return result + errormsg

    def ssh2node_job(self, cmd):
        stdin, stdout, stderr = self.ssh.exec_command(cmd)
        result = stdout.read()
        error = stderr.read()
        return result, error


    def scp2node(self, scp_file, remote_file):
        sftp = paramiko.SFTPClient.from_transport(self.transport)
        sftp.put(scp_file, remote_file)

    def is_ha_not(self):
        cmd = 'cat /proc/cmdline |grep HA'
        result = self.ssh2node(cmd)
        if result:
            return 1
        else:
            return 0

    def is_flash(self):
        cmd = '/opt/oracle/oak/bin/odaadmcli show diskgroup|grep -i FLASH'
        result = self.ssh2node(cmd)
        if result:
            return 1
        else:
            return 0


    def is_bonding_or_not(self):
        cmd = "ls /etc/sysconfig/network-scripts/ifcfg-btbond1"
        result = self.ssh2node(cmd)
        print result
        if re.search("No such", result):
            return 0
        else:
            return 1


    def run_cmd(self, cmd):
        print cmd
        sys.stdout.flush()
        result,error = self.ssh2node_job(cmd)
        if error:
            print error
            sys.stdout.flush()
            return 0
        else:
            print result
            sys.stdout.flush()

        #d = simplejson.loads(result)
        #jobid = d['jobId']
        #jobid = re.findall(r'jobId.*:\s*"(\S+)"', result)
        jobid = re.search('jobId.*"(\S+)"', result).group(1)

        if not jobid:
            return 0
        time.sleep(10)
        cmd1 = Oda_ha.ODACLI + "describe-job -j -i %s" % jobid
        while True:
            tasks = self.ssh2node(cmd1)
            #job_status = re.findall('Status:\s*(\S+)', tasks)[0]
            a = simplejson.loads(tasks)
            job_status = a['status']
            if job_status.lower() == 'success':
                return 1
            elif job_status.lower() == 'running':
                time.sleep(5)
            else:
                print "job failed!\n"
                sys.stdout.flush()
                return 0

    def create_database(self, options):
        cmd = Oda_ha.ODACLI + 'create-database -j ' + options
        result = self.run_cmd(cmd)
        return result


    def delete_database(self, options):
        cmd = Oda_ha.ODACLI + 'delete-database -j ' + options
        result = self.run_cmd(cmd)
        return result

    def delete_dbhome(self, options):
        cmd = Oda_ha.ODACLI + 'delete-dbhome -j ' + options
        result = self.run_cmd(cmd)
        return result

    def describe_database(self,options):
        cmd = Oda_ha.ODACLI + 'describe-database -j ' + options
        result = self.ssh2node(cmd)
        d = simplejson.loads(result)
        return d

    def describe_appliance(self):
        cmd = Oda_ha.ODACLI + 'describe-appliance -j '
        result = self.ssh2node(cmd)
        d = simplejson.loads(result)
        return d


    def describe_dbhome(self,options):
        cmd = Oda_ha.ODACLI + 'describe-dbhome -j ' + options
        result = self.ssh2node(cmd)
        d = simplejson.loads(result)
        return d

    def update_database(self, options):
        cmd = Oda_ha.ODACLI + 'update-database -j ' + options
        result = self.run_cmd(cmd)
        return result

    def create_backup(self, options):
        cmd = Oda_ha.ODACLI + 'create-backup -j ' + options
        result = self.run_cmd(cmd)
        return result


    def disable_auto_backup(self):
        cmd = Oda_ha.ODACLI + "list-schedules |grep backup| awk '{print $1}'"
        result = self.ssh2node(cmd)
        if not result:
            print "no auto backup schedules!\n"
            sys.stdout.flush()
            return 0
        result1 = result.split()
        for i in result1:
            d_cmd = Oda_ha.ODACLI + "update-schedule -i %s -d" % i
            self.ssh2node(d_cmd)
        else:
            return 1

    def delete_backupconfig(self, options):
        cmd = Oda_ha.ODACLI + 'delete-backupconfig -j ' + options
        result = self.run_cmd(cmd)
        return result

    def create_backupconfig(self, options):
        cmd = Oda_ha.ODACLI + 'create-backupconfig -j ' + options
        result = self.run_cmd(cmd)
        return result

    def describe_backupconfig(self, options):
        cmd = Oda_ha.ODACLI + 'describe-backupconfig -j ' + options
        result = self.ssh2node(cmd)
        d = simplejson.loads(result)
        return d

    def create_objectstoreswift(self, options):
        """
        url_oss = "https://swiftobjectstorage.us-phoenix-1.oraclecloud.com/v1"
        tenant_name_oss = "dbaasimage"
        user_name_oss = 'chunling.qin@oracle.com'
        password_oss = 'wgT.ZM&>U6Tmm#F]O&9n'
        """
        url_oss = "https://storage.oraclecorp.com/v1"
        tenant_name_oss = "Storage-vidsunda"
        user_name_oss = 'vidsunda.Storageadmin'
        password_oss = 'Objwelcome1'
        op = "-n %s -e %s -hp '%s' -t %s -u %s" % (options, url_oss, password_oss, tenant_name_oss, user_name_oss)
        cmd = Oda_ha.ODACLI + 'create-objectstoreswift -j ' + op
        result = self.run_cmd(cmd)
        return result

    def delete_objectstoreswift(self, options):
        cmd = Oda_ha.ODACLI + 'delete-objectstoreswift -j ' + options
        result = self.run_cmd(cmd)
        return result

    def describe_objectstoreswift(self, options):
        cmd = Oda_ha.ODACLI + 'describe-objectstoreswift -j ' + options
        result = self.ssh2node(cmd)
        d = simplejson.loads(result)
        return d

    def describe_backupreport(self, options):
        cmd = Oda_ha.ODACLI + 'describe-backupreport -j ' + options
        result = self.ssh2node(cmd)
        return result

    def dbnametodbhome(self, dbname):
        d = self.describe_database("-in %s" %dbname)
        dbhomeid = d['dbHomeId']
        dbhome = self.describe_dbhome("-i %s" %dbhomeid)
        return dbhome['dbHomeLocation']

    def racuser(self):
        #cmd = "ls -ld /u01/app/*/product/*/dbhome_*|awk '{print $3}'|uniq"
        cmd = "ls /home/"
        result = self.ssh2node(cmd).split()
        giuser = self.griduser()
        if len(result) == 1 and result[0] == giuser:
            return giuser
        else:
            result.remove(giuser)
            return result[0]


    def griduser(self):
        cmd = "ls /u01/app/1*/|tail -n 1"
        result = self.ssh2node(cmd)
        return result


    def gridgroup(self):
        griduser = self.griduser()
        cmd = "ls -ld /home/%s|awk '{print $4}'" % griduser
        result = self.ssh2node(cmd)
        return result


    def racgroup(self):
        racuser = self.racuser()
        cmd = "ls -ld /home/%s|awk '{print $4}'" % racuser
        result = self.ssh2node(cmd)
        return result


    def dbnametoinstance(self, dbname):
        cmd = "ps -ef|grep ora_pmon_%s |grep -v grep|awk '{print $8}'" % dbname
        result = self.ssh2node(cmd)
        return result[9:]

    def recover_database(self, options):
        cmd = Oda_ha.ODACLI + 'recover-database -j ' + options
        result = self.run_cmd(cmd)
        return result


    def describe_component(self):
        cmd = Oda_ha.ODACLI + 'describe-component -j '
        result = self.ssh2node(cmd)
        return result

    def update_repository(self, options):
        cmd = Oda_ha.ODACLI + 'update-repository -j ' + options
        result = self.run_cmd(cmd)
        return result


    def update_dcsagent(self, options):
        cmd = Oda_ha.ODACLI + 'update-dcsagent -j ' + options
        result = self.run_cmd(cmd)
        return result

    def update_server(self, options):
        cmd = Oda_ha.ODACLI + 'update-server -j ' + options
        result = self.run_cmd(cmd)
        return result


    def create_appliance(self, options):
        cmd = Oda_ha.ODACLI + 'create-appliance -j ' + options
        result = self.run_cmd(cmd)
        return result

    def update_dbhome(self, options):
        cmd = Oda_ha.ODACLI + 'update-dbhome -j ' + options
        result = self.run_cmd(cmd)
        return result

    def extend_u01(self):
        cmd1 = "df -h /u01|awk 'NR>2 {print $1}'"
        result = self.ssh2node(cmd1)
        result1 = re.search('(\d+)', result).group()
        if int(result1) < 100:
            cmd2 = "lvextend -L +100G /dev/VolGroupSys/LogVolU01;resize2fs /dev/VolGroupSys/LogVolU01"
            self.ssh2node(cmd2)

    def crs_status(self):
        self.scp2node('stats.sh','/tmp/stats.sh')
        cmd = 'sh /tmp/stats.sh'
        result = self.ssh2node(cmd)
        return result

    def create_dbhome(self, options):
        cmd = Oda_ha.ODACLI + 'create-dbhome -j ' + options
        result = self.run_cmd(cmd)
        return result

    def delete_dbhome(self, options):
        cmd = Oda_ha.ODACLI + 'delete-dbhome -j ' + options
        result = self.run_cmd(cmd)
        return result

    def create_dbstorage(self, options):
        cmd = Oda_ha.ODACLI + 'create-dbstorage -j ' + options
        result = self.run_cmd(cmd)
        return result

    def delete_dbstorage(self, options):
        cmd = Oda_ha.ODACLI + 'delete-dbstorage -j ' + options
        result = self.run_cmd(cmd)
        return result

    def describe_dbstorage(self, options):
        cmd = Oda_ha.ODACLI + 'describe-dbstorage -j ' + options
        result = self.ssh2node(cmd)
        d = simplejson.loads(result)
        return d

    def decribe_cpucore(self):
        cmd = Oda_ha.ODACLI + 'describe-cpucore -j '
        result = self.ssh2node(cmd)
        d = simplejson.loads(result)
        return d

    def update_cpucore(self, options):
        cmd = Oda_ha.ODACLI + 'update-cpucore -j ' + options
        result = self.run_cmd(cmd)
        return result