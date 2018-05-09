"""
This module is used to login and logout ODA or ODALite UI

"""

import time
import ui_common_method as cm

# from selenium.webdriver.common.keys import Keys

user_name = "oda-admin"
password = "welcome1"
password2 = "WElcome12_-"

driver1 = cm.driver1
ui = cm.ui
ec = cm.ec
By = cm.By


def login(node, driver=driver1):
    if node in ["scaoda704c1n", "scaoda710c1n"]:
        url = "https://%s.us.oracle.com:7093/mgmt/index.html" % (node + "1")
    elif node in ["10.31.129.245", "10.31.130.36"]:
        url = "https://%s:7093/mgmt/index.html" % node
    else:
        url = "https://%s.us.oracle.com:7093/mgmt/index.html" % node
    driver.get(url)
    driver.implicitly_wait(30)
    driver.maximize_window()

    ui.WebDriverWait(driver, 30).until(ec.visibility_of_element_located((By.ID, "username")))

    driver.find_element_by_id("username").clear()
    driver.find_element_by_id("username").send_keys(user_name)
    driver.find_element_by_id("password").clear()
    driver.find_element_by_id("password").send_keys(password2)
    # time.sleep(10)
    # driver.find_element_by_name("submit").click()
    # driver.find_element_by_xpath('//*[@class="login-input"]/*[@name="submit"]').click()
    driver.find_element_by_css_selector('[ value="Login"]').click()
    time.sleep(2)
    a = driver.find_elements_by_xpath('//*[@id="SigninFailure"]/div[1]/button')
    if len(a):
        a[0].click()
        time.sleep(2)
        resetpassword(driver)

    # else:
    # print "Could not login UI"


def logout(driver=driver1):
    driver.quit()


def resetpassword(driver):
    driver.find_element_by_id("username").clear()
    driver.find_element_by_id("username").send_keys(user_name)
    driver.find_element_by_id("password").clear()
    driver.find_element_by_id("password").send_keys(password)
    driver.find_element_by_css_selector('[ value="Login"]').click()
    time.sleep(2)
    result = ec.alert_is_present()(driver)
    if result:
        result.accept()
    ui.WebDriverWait(driver, 30).until(ec.visibility_of_element_located((By.ID, "adminPassword")))
    driver.find_element_by_id("adminPassword").clear()
    driver.find_element_by_id("adminPassword").send_keys(password2)
    time.sleep(1)
    driver.find_element_by_id("adminPasswordRepeat").clear()
    driver.find_element_by_id("adminPasswordRepeat").send_keys(password2)
    driver.find_element_by_css_selector('[value="Submit"]').click()
    ui.WebDriverWait(driver, 30).until(ec.visibility_of_element_located((By.ID, "okUserSettingButton")))
    time.sleep(10)
    driver.find_element_by_css_selector("#okUserSettingButton>div>span").click()
    ui.WebDriverWait(driver, 30).until(ec.visibility_of_element_located((By.ID, "username")))
    time.sleep(5)
    driver.find_element_by_id("username").clear()
    driver.find_element_by_id("username").send_keys(user_name)
    driver.find_element_by_id("password").clear()
    driver.find_element_by_id("password").send_keys(password2)
    driver.find_element_by_css_selector('[ value="Login"]').click()
    result = ec.alert_is_present()(driver)
    if result:
        result.accept()


if __name__ == "__main__":
    login("scaoda704c1n")
