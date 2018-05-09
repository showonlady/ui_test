#
# This script is for object store page

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
oss_name = cm.gen_random_string(string1, 20)
oss_credential ={"objectStoreName" : "%s" % oss_name,
                 "endpointUrl" : "https://swiftobjectstorage.us-phoenix-1.oraclecloud.com/v1",
                 "tenantName" : "dbaasimage",
                 "userName" : "chunling.qin@oracle.com",
                 "password" : "wgT.ZM&>U6Tmm#F]O&9n"
                 }

node = "scaoda704c1n"
def main():
    if node in ["rwsoda6s005", "scaoda7m005", "scaoda710c1n","rwsoda6f004","rwsoda6m005","scaoda7s005","scaoda704c1n", "10.31.129.245", "10.31.130.36"]:
        ll.login(node)
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.CSS_SELECTOR, "ul>li:nth-child(5)>a[role='button']>span")))
        driver.find_element_by_css_selector("ul>li:nth-child(5)>a[role='button']>span").click()
        a = driver.find_elements_by_xpath('//*[@id="initialObjectStore"]/div/button/div/span')
        if (len(a) == 0):
            driver.find_element_by_xpath('//*[@id="createObjectStore"]/div/span').click()
        else:
            a[0].click()
        for key, value in oss_credential.items():
            cm.by_id_input(key, value)
        cm.by_id_input("repeatPasssword", "wgT.ZM&>U6Tmm#F]O&9n")
        driver.find_element_by_xpath('//*[@id="okCreateObjectStoreCreds"]/div/span').click()
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "yesButton")))
        time.sleep(3)
        driver.find_element_by_id("yesButton").click()
        ui.WebDriverWait(driver, 30).until(ec.visibility_of_element_located((By.ID, "createObjectStoreCredSubmitDialog")))
        time.sleep(2)
        driver.find_element_by_xpath("//*[@id='createObjectStoreCredSubmitDialog']/div[2]/div/div/div[3]/a").click()



if __name__ == "__main__":
    main()
