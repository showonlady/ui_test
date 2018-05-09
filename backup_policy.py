#
# This script is for backup policy

import time
import random
import ui_common_method as cm
import ui_login_logout as ll
import string

driver = cm.driver
ui = cm.ui
ec = cm.ec
By = cm.By

string1 = string.ascii_letters + string.digits
backup_policy_name = cm.gen_random_string(string1, 20)
destnation = "ObjectStore"

node = "scaoda704c1n"


def main():
    if node in ["rwsoda6s005", "scaoda7m005", "scaoda710c1n", "rwsoda6f004", "rwsoda6m005", "scaoda7s005",
                "scaoda704c1n", "10.31.129.245"]:
        ll.login(node)
        ui.WebDriverWait(driver, 30).until(
            ec.element_to_be_clickable((By.CSS_SELECTOR, "ul>li:nth-child(5)>a[role='button']>span")))
        driver.find_element_by_css_selector("ul>li:nth-child(3)>a[role='button']>span").click()
        time.sleep(2)
        driver.find_element_by_xpath('//*[@id="database"]/a/span').click()
        time.sleep(2)
        driver.find_element_by_xpath('// *[ @ id = "dbhome"]/a/span').click()
        time.sleep(2)
        driver.find_element_by_xpath('//*[@id="backupPolicy"]/a/span').click()
        a = driver.find_elements_by_xpath('//*[@id="initialBackupPolicy"]/div/button/div/span')

        if (len(a) == 0):
            driver.find_element_by_xpath('//*[@id="createBackupPolicy"]/div[1]/span').click()
        else:
            a[0].click()
        cm.by_id_input("backupPolicyName", "%s" % backup_policy_name)
        cm.by_id_select("ojChoiceId_backupDestinationId_selected",
                        '//*[@id="oj-listbox-results-backupDestinationId"]/li[2]/div')
        cm.by_id_input("containerName", "chqin")
        cm.option_random_choice('ojChoiceId_objectStoreSelectionName_selected',
                                '//*[@id="oj-listbox-results-objectStoreSelectionName"]/li/div')
        driver.find_element_by_xpath('//*[@id="okCreateBackupPolicy"]/div/span').click()
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "yesButton")))
        time.sleep(3)
        driver.find_element_by_id("yesButton").click()
        time.sleep(2)
        driver.find_element_by_xpath('//*[@id="createBackupPolicySubmitDialog"]/div[2]/div/div/div[3]/a').click()


if __name__ == "__main__":
    main()
