#
# This script is for db backup

import time
import ui_common_method as cm
import ui_login_logout as ll
import random


driver = cm.driver
ui = cm.ui
ec = cm.ec
By = cm.By
node = "scaoda704c1n"
dbname = "J"
backup_password = "WElcome12_-"


def main():
    if node in ["rwsoda6s005", "scaoda7m005", "scaoda710c1n", "rwsoda6f004", "rwsoda6m005", "scaoda7s005",
                "scaoda704c1n", "10.31.129.245"]:
        ll.login(node)
        ui.WebDriverWait(driver, 30).until(
            ec.element_to_be_clickable((By.CSS_SELECTOR, "ul>li:nth-child(5)>a[role='button']>span")))
        driver.find_element_by_css_selector("ul>li:nth-child(5)>a[role='button']>span").click()
        time.sleep(2)
        driver.find_element_by_css_selector("ul>li:nth-child(3)>a[role='button']>span").click()
        time.sleep(10)
        driver.find_element_by_xpath('// *[ @ id = "dbhome"]/a/span').click()
        time.sleep(5)
        driver.find_element_by_xpath('//*[@id="database"]/a/span').click()
        dbs = driver.find_elements_by_xpath('// *[ @ id = "listview"]/li/div/div/div/div/*[text() = "%s"]' % dbname)
        if len(dbs) == 0:
            print "There is no databases named %s!" % dbname
        else:
            dbs[0].click()
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "applyBackupPolicy")))
        driver.find_element_by_xpath('//*[@id="applyBackupPolicy"]/div/span').click()
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "ojChoiceId_backupPolicyNameId_selected")))
        cm.option_random_choice("ojChoiceId_backupPolicyNameId_selected", '//*[@id="oj-listbox-results-backupPolicyNameId"]/li/div')
        cm.by_id_input("password","%s" % backup_password)
        cm.by_id_input("cpassword", "%s" % backup_password)
        driver.find_element_by_xpath('//*[@id="okApplyBackupPolicy"]/div/span').click()
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "applyBackupPolicySubmitDialog")))
        time.sleep(1)
        driver.find_element_by_xpath('//*[@id="applyBackupPolicySubmitDialog"]/div/div/div/div[3]/a').click()




if __name__ == "__main__":
    main()
