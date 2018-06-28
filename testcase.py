#!/user/bin/env python
#encoding unitest

import unittest
import create_database as c_d
import create_backupconfig as c_b
import backup_recovery as b_r
import oda_lib
import re
import oda_patch as o_p
import dbhome_check as d_c
import dbstorage_check as ds_c
import cpucore_check as cpu_c
import sys
import common_fun as cf

"""
def extend_u01(hostname, username, password):
    cmd1 = "df -h /u01|awk 'NR>2 {print $1}'"
    host = oda_lib.Oda_ha(hostname, username, password)
    result = host.ssh2node(cmd1)
    result1 = re.search('(\d+)', result).group()
    if int(result1) < 100:
        cmd2 = "lvextend -L +100G /dev/VolGroupSys/LogVolU01;resize2fs /dev/VolGroupSys/LogVolU01"
        host.ssh2node(cmd2)

"""

class Test(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        hostname = raw_input("input the hostname:")
        cls.hostname = hostname
        cls.username = "root"
        cls.password = "welcome1"
        host = oda_lib.Oda_ha(cls.hostname, cls.username, cls.password)
        cf.extend_space_u01(host)
        #cmd = "lvextend -L +100G /dev/VolGroupSys/LogVolU01;resize2fs /dev/VolGroupSys/LogVolU01"
        #host = oda_lib.Oda_ha(hostname,username,password)
        #host.ssh2node(cmd)


    @classmethod
    def tearDownClass(cls):
        pass




    def test_03_create_database(self):
        result = c_d.main(self.hostname, self.username, self.password)
        self.assertTrue(result)
        
    def test_02_create_backupconfig(self):
        result = c_b.main(self.hostname, self.username, self.password)
        self.assertTrue(result)
    
    def test_04_backup_recovery(self):
        result = b_r.main(self.hostname, self.username, self.password)
        self.assertTrue(result)

    def test_05_dbhome_check(self):
        result = d_c.main(self.hostname, self.username, self.password)
        self.assertTrue(result)

    def test_06_dbstorage_check(self):
        result = ds_c.main(self.hostname, self.username, self.password)
        self.assertTrue(result)

    def test_07_cpucore_check(self):
        result = cpu_c.main(self.hostname, self.username, self.password)
        self.assertTrue(result)

if __name__ == "__main__":
    unittest.main()
