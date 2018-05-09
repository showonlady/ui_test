#
# This script helps to auto provisioning on UI page

import time
import random
import ui_common_method as cm
import ui_login_logout as ll
import ui_element_system as es
import ui_element_db as ed
import ui_element_user as eu
import ui_element_asr as ea

driver = cm.driver1
ui = cm.ui
ec = cm.ec
By = cm.By

#node = "10.31.130.36"
node = raw_input("Then node name(like scaoda704c1n): ")
print "The node % s will be provisioned!\n" % node
InitialDb = random.choice(["yesInitialDb", "noInitialDb"])
#UserGroup = random.choice(["yesUserGroup", "noUserGroup"])
UserGroup = random.choice(["noUserGroup"])
Asr = random.choice(["yesAsr", "noAsr"])


def main():
    if node in ["rwsoda6s005", "scaoda7m005", "scaoda710c1n", "rwsoda6f004", "rwsoda6m005", "scaoda7s005", "scaoda704c1n", "10.31.129.245", "10.31.130.36"]:
        ll.login(node)
        ui.WebDriverWait(driver, 30).until(ec.visibility_of_element_located((By.ID, "getStartContainer")))
        driver.find_element_by_xpath('//*[@id="getStartContainer"]/button/div/span').click()

        es.input_system_network(node)
        if UserGroup == "yesUserGroup":
            cm.by_id_click("%s" % UserGroup)
            eu.input_custom_user()
        if InitialDb == "yesInitialDb":
            ed.input_db()
        elif InitialDb == "noInitialDb":
            cm.by_id_click("%s" % InitialDb)
        if Asr == "yesAsr":
            cm.by_id_click("%s" % Asr)
            ea.config_asr()

        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "submit")))
        driver.find_element_by_id('submit').click()
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "confirmDialogYesButton")))
        time.sleep(1)
        driver.find_element_by_id('confirmDialogYesButton').click()
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "JobSubmitDialog")))
        time.sleep(1)
        driver.find_element_by_xpath('//*[@id="JobSubmitDialog"]/div/div/div/div[3]/a').click()
        time.sleep(120)
    else:
        print "This node is NOT supported"
    ll.logout()


if __name__ == "__main__":
    main()
