#
# This script is for db creation

import time
import ui_common_method as cm
import ui_login_logout as ll
import ui_element_db as ed

driver = cm.driver
ui = cm.ui
ec = cm.ec
By = cm.By
node = "scaoda704c1n"


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
        a = driver.find_elements_by_xpath('//*[@id="initialDb"]/div/button/div/span')
        if len(a) == 0:
            driver.find_element_by_xpath('//*[@id="createDatabase"]/div/span').click()
        else:
            a[0].click()
        time.sleep(1)
        driver.find_element_by_xpath('//*[@id="nextCreateDbButtonId"]/div/span').click()
        time.sleep(1)
        ed.input_db("password", "cpassword")
        driver.find_element_by_xpath('//*[@id="okCreateDb"]/div/span').click()
        time.sleep(1)
        cm.by_id_click('yesButton')
        ui.WebDriverWait(driver, 30).until(ec.element_to_be_clickable((By.ID, "createDbSubmitDialog")))
        time.sleep(1)
        driver.find_element_by_xpath('//*[@id="createDbSubmitDialog"]/div[2]/div/div/div[3]/a')


if __name__ == "__main__":
    main()
