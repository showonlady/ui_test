#
# This script is for some basic ui operation

import ui_common_method as cm
import time
import string
import ui_element_db as ed
import random
import os
import traceback
from selenium.webdriver.common.action_chains import ActionChains

ui = cm.ui
ec = cm.ec
By = cm.By

backuprmanpassword = "WElcome123#_"
dbsyspassword = "WElcome12_-"
string1 = string.ascii_letters + string.digits
string2 = string.ascii_letters + string.digits + "_"

dbName = cm.gen_random_string(string1, 8)
dbUniqueName = cm.gen_random_string(string2, 30)
db1 = 'db1'

oss_name = cm.gen_random_string(string1, 20)
oss_credential = {"objectStoreName": "%s" % oss_name,
                  "endpointUrl": "https://swiftobjectstorage.us-phoenix-1.oraclecloud.com/v1",
                  "tenantName": "dbaasimage",
                  "userName": "chunling.qin@oracle.com",
                  "password": "wgT.ZM&>U6Tmm#F]O&9n"
                  }

backup_policy_name = cm.gen_random_string(string1, 20)


def submit_job_status(driver, x):
    time.sleep(30)
    ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, x)))
    time.sleep(1)
    try:
        driver.find_element_by_xpath('//*[@id="%s"]/div[2]/div[1]/div[1]/div[3]/a' % x).click()
        return True
    except Exception as e:
        traceback.print_exc()
        return False


def go_object_store_tab(driver):
    ui.WebDriverWait(driver, 30).until(
        ec.element_to_be_clickable((By.CSS_SELECTOR, "ul>li:nth-child(5)>a[role='button']>span")))
    driver.find_element_by_css_selector("ul>li:nth-child(5)>a[role='button']>span").click()


def create_object_store(driver):
    a = driver.find_elements_by_xpath('//*[@id="initialObjectStore"]/div/button/div/span')
    if len(a) == 0:
        driver.find_element_by_xpath('//*[@id="createObjectStore"]/div/span').click()
    else:
        a[0].click()
    for key, value in oss_credential.items():
        cm.by_id_input(key, value, driver)
    cm.by_id_input("repeatPasssword", "wgT.ZM&>U6Tmm#F]O&9n", driver)
    driver.find_element_by_xpath('//*[@id="okCreateObjectStoreCreds"]/div/span').click()
    ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "yesButton")))
    time.sleep(3)
    driver.find_element_by_id("yesButton").click()
    status = submit_job_status(driver, "createObjectStoreCredSubmitDialog")
    return status


def go_database_tab(driver):
    ui.WebDriverWait(driver, 30).until(
        ec.element_to_be_clickable((By.CSS_SELECTOR, "ul>li:nth-child(3)>a[role='button']>span")))
    driver.find_element_by_css_selector("ul>li:nth-child(3)>a[role='button']>span").click()


def go_database_tab_backuppolicy(driver):
    driver.find_element_by_xpath('//*[@id="backupPolicy"]/a/span').click()


def go_database_tab_dbhome(driver):
    driver.find_element_by_xpath('// *[ @ id = "dbhome"]/a/span').click()


def go_database_tab_database(driver):
    driver.find_element_by_xpath('//*[@id="database"]/a/span').click()


def create_backuppolicy_oss(driver):
    rw = random.randint(1, 30)
    a = driver.find_elements_by_xpath('//*[@id="initialBackupPolicy"]/div/button/div/span')
    if len(a) == 0:
        driver.find_element_by_xpath('//*[@id="createBackupPolicy"]/div[1]/span').click()
    else:
        a[0].click()
    cm.by_id_input("backupPolicyName", "%s" % backup_policy_name, driver)
    ###choose the oss as the destination##
    cm.by_id_select("ojChoiceId_backupDestinationId_selected",
                    '//*[@id="oj-listbox-results-backupDestinationId"]/li[2]/div', driver)
    cm.by_id_input("containerName", "chqin", driver)
    cm.by_id_input("recoveryWindow", '%s' % rw, driver)
    cm.option_random_choice('ojChoiceId_objectStoreSelectionName_selected',
                            '//*[@id="oj-listbox-results-objectStoreSelectionName"]/li/div', driver)
    driver.find_element_by_xpath('//*[@id="okCreateBackupPolicy"]/div/span').click()
    ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "yesButton")))
    time.sleep(3)
    driver.find_element_by_id("yesButton").click()
    time.sleep(2)
    status = submit_job_status(driver, "createBackupPolicySubmitDialog")
    return status


def create_database(driver):
    go_database_tab_database_create_database_tab(driver)
    time.sleep(1)
    driver.find_element_by_xpath('//*[@id="nextCreateDbButtonId"]/div/span').click()
    time.sleep(1)
    dbhome = random.choice([True, False])
    ed.input_db("password", "cpassword", dbhome, db1, driver)
    driver.find_element_by_xpath('//*[@id="okCreateDb"]/div/span').click()
    time.sleep(1)
    cm.by_id_click('yesButton', driver)
    status = submit_job_status(driver, "createDbSubmitDialog")
    return status


def go_database_tab_database_create_database_tab(driver):
    a = driver.find_elements_by_xpath('//*[@id="initialDb"]/div/button/div/span')
    if len(a) == 0:
        driver.find_element_by_xpath('//*[@id="createDatabase"]/div/span').click()
    else:
        a[0].click()


def create_database_frombackup_restore_page(driver):
    jsonfile_path = "D:\sendjsonfile.exe D:\my.json"
    numofchannel = random.randint(1, 5)
    using_existing_dbhome = random.choice([True, False])
    emconsole = random.choice(["noBackupReportEnableConsole", "yesBackupReportEnableConsole"])
    cm.option_random_choice("ojChoiceId_objectStoreSelectionName_selected", '//*[@id="oj-listbox-results'
                                                                            '-objectStoreSelectionName"]/li/div',
                            driver)
    driver.find_element_by_id("backupReportFileId").click()
    time.sleep(3)
    os.system(jsonfile_path)
    cm.by_id_input("backupReportRmanPasswords", backuprmanpassword, driver)
    cm.by_id_input("backupReportRmanPasswordsRepeat", backuprmanpassword, driver)
    cm.by_id_input("bkupReportDbName", dbName, driver)
    cm.by_id_input("bkupReportDbUniqueName", dbUniqueName, driver)
    if using_existing_dbhome:
        driver.find_element_by_id("existingBackupReportDbHome").click()
        if cm.is_element_exist_by_id("oj-listbox-results-backupReportDbHome", driver):
            cm.option_random_choice("oj-select-choice-backupReportDbHome",
                                    '//*[@id="oj-listbox-results-backupReportDbHome"]/li/div', driver)
        else:
            create_dbfrombackup_choose_dbversion(driver)
    else:
        create_dbfrombackup_choose_dbversion(driver)
    if cm.is_element_exist_by_id("ojChoiceId_bkupReportDbType_selected", driver):
        cm.option_random_choice("ojChoiceId_bkupReportDbType_selected",
                                '//*[@id="oj-listbox-results-bkupReportDbType"]/li/div', driver)
    cm.option_random_choice("ojChoiceId_bkupReportDbShape_selected",
                            '//*[@id="oj-listbox-results-bkupReportDbShape"]/li/div', driver)

    cm.option_random_choice("oj-select-choice-bkupReportDbClass",
                            '//*[@id="oj-listbox-results-bkupReportDbClass"]/li/div[not(@aria-disabled)]', driver)
    cm.option_random_choice("ojChoiceId_bkupReportDbStorage_selected",
                            '//*[@id="oj-listbox-results-bkupReportDbStorage"]/li/div[not(@aria-disabled)]', driver)
    # cm.by_id_input("noOfRmanChannels", numofchannel, driver)
    time.sleep(2)
    if emconsole == "yesBackupReportEnableConsole":
        cm.by_id_click(emconsole, driver)
    cm.by_id_input("bkupReportSysPassword", '%s' % dbsyspassword, driver)
    cm.by_id_input("bkupReportCSysPassword", '%s' % dbsyspassword, driver)
    driver.find_element_by_xpath('//*[@id="okRestoreDb"]/div/span[1]').click()
    time.sleep(1)
    cm.by_id_click("yesCreateDbUsingExistingBackup", driver)


def create_dbfrombackup_choose_dbversion(driver):
    driver.find_element_by_id("newBackupReportDbHome").click()
    cm.option_random_choice("ojChoiceId_backupReportDbVersion_selected",
                            '// *[ @ id = "oj-listbox-results-backupReportDbVersion"]/li/div', driver)


def create_dbfrombackup(driver):
    go_database_tab_database_create_database_tab(driver)
    time.sleep(1)
    driver.find_element_by_id("createDbFromBackupId").click()
    time.sleep(1)
    driver.find_element_by_xpath('//*[@id="nextCreateDbButtonId"]/div/span[1]').click()
    time.sleep(1)
    create_database_frombackup_restore_page(driver)
    status = submit_job_status(driver, "createDbFromBackupSubmitDialog")
    return status


def restore_dbfrombackup(driver):
    go_database_tab_database_create_database_tab(driver)
    time.sleep(1)
    driver.find_element_by_id("restoreDbFromBackupId").click()
    time.sleep(1)
    driver.find_element_by_xpath('//*[@id="nextCreateDbButtonId"]/div/span[1]').click()
    time.sleep(1)
    create_database_frombackup_restore_page(driver)
    status = submit_job_status(driver, "restoreDbFromBackupSubmitDialog")
    return status


def find_db_to_apply_backup_policy(driver):
    # a = driver.find_elements_by_xpath('//*[@id="listview"]/li/div/div/div/div/a')
    go_db_page_with_name(driver)
    ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "applyBackupPolicy")))
    driver.find_element_by_xpath('//*[@id="applyBackupPolicy"]/div/span').click()
    ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "oj-select-choice-backupPolicyNameId")))
    cm.option_random_choice("oj-select-choice-backupPolicyNameId",
                            '//*[@id="oj-listbox-results-backupPolicyNameId"]/li/div', driver)
    cm.by_id_input("password", '%s' % backuprmanpassword, driver)
    cm.by_id_input("cpassword", '%s' % backuprmanpassword, driver)
    driver.find_element_by_xpath('//*[@id="okApplyBackupPolicy"]/div/span').click()
    status = submit_job_status(driver, "applyBackupPolicySubmitDialog")
    return status


def go_db_page_with_name(driver):
    a = driver.find_elements_by_xpath('//*[text() = "%s"]' % db1)
    if len(a) == 0:
        print "Create a db first!\n"
        return False
    else:
        random.choice(a).click()
    ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "applyBackupPolicy")))


def db_backup(driver, backuptype):
    go_db_page_with_name(driver)
    driver.find_element_by_xpath('//*[@id="manualBackupButton"]/div/span').click()
    time.sleep(5)
    cm.by_id_select("ojChoiceId_backupType_selected", '//*[text() = "%s"]' % backuptype, driver)
    cm.by_id_input("backupTag", "ui_test", driver)


def confirm_ok_yes(driver, x, y):
    driver.find_element_by_xpath('//*[@id="%s"]/div/span[1]' % x).click()
    ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, y)))
    time.sleep(1)
    driver.find_element_by_id(y).click()
    time.sleep(1)


def db_backup_l0(driver):
    db_backup(driver, "Level 0 Incremental Backup")
    confirm_ok_yes(driver, "okManualBackup", "yesManualBackup")
    status = submit_job_status(driver, "manualBackupSubmitDialog")
    return status


def db_backup_l1(driver):
    db_backup(driver, "Level 1 Incremental Backup")
    confirm_ok_yes(driver, "okManualBackup", "yesManualBackup")
    status = submit_job_status(driver, "manualBackupSubmitDialog")
    return status


def db_backup_archive_log(driver):
    db_backup(driver, "Archive Log Backup")
    confirm_ok_yes(driver, "okManualBackup", "yesManualBackup")
    status = submit_job_status(driver, "manualBackupSubmitDialog")
    return status


def db_backup_longterm(driver):
    num = random.randint(1, 30)
    db_backup(driver, "Longterm Backup")
    cm.by_id_input("keepDays", num, driver)
    confirm_ok_yes(driver, "okManualBackup", "yesManualBackup")
    status = submit_job_status(driver, "manualBackupSubmitDialog")
    return status


def disable_autobackup(driver):
    go_db_page_with_name(driver)
    driver.find_element_by_xpath('//*[@id="updateBackupSchedule"]/div/span').click()
    time.sleep(1)
    driver.find_element_by_id("autoBackup").click()
    confirm_ok_yes(driver, "okUpdateBackupSchedule", "yesUpdateBackupSchedule")
    driver.find_element_by_xpath('//*[@id="updateBackupScheduleSubmitDialog"]/div[1]/button/div/span[1]').click()


def disable_archivelog_backup(driver):
    go_db_page_with_name(driver)
    driver.find_element_by_xpath('//*[@id="updateArchiveLogBackupSchedule"]/div/span').click()
    time.sleep(1)
    driver.find_element_by_id("autoBackup").click()
    confirm_ok_yes(driver, "okUpdateBackupSchedule", "yesUpdateBackupSchedule")
    driver.find_element_by_xpath('//*[@id="updateBackupScheduleSubmitDialog"]/div[1]/button/div/span[1]').click()


def random_pickup_a_db(driver):
    a = driver.find_elements_by_xpath('//*[@id="listview"]/li/div/div/div/div/a')
    if len(a) == 0:
        print "No db found, create one first!\n"
    else:
        return random.choice(a).text
