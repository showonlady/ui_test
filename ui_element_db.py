"""
This script includes database elements on UI page
"""
import re
import time
import random
import string
import ui_common_method as cm
import ui_login_logout as ll

flash_list = ["yesFlash", "noFlash"]
node_list = ["nodeNumber0", "nodeNumber1"]
EmConsole = random.choice(["yesEmConsole", "noEmConsole"])
password2 = "WElcome12_-"

string1 = string.ascii_letters + string.digits
string2 = string.ascii_letters + string.digits + "_"

dbName = cm.gen_random_string(string1, 8)

dbUniqueName = cm.gen_random_string(string2, 30)
pdbName = cm.gen_random_string(string2, 30)
pdbAdmin = cm.gen_random_string(string2, 30)

pdbName_text_box = {
    "pdbName": "%s" % pdbName,
    "pdbAdmin": "%s" % pdbAdmin}

"""
dbName_text_box = {
    "dbName": "%s" % dbName,
    "dbUniqueName": "%s" % dbUniqueName}
"""
"""	
db_choice = {
    "ojChoiceId_dbVersion_selected" : '//*[@id="oj-listbox-results-dbVersion"]/li/div[not (@aria-disabled)]',
    "ojChoiceId_dbEdition_selected" : '//*[@id="oj-listbox-results-dbEdition"]/li/div',
    "oj-select-choice-dbShape" : '//*[@id="oj-listbox-results-dbShape"]/li/div',
    "ojChoiceId_dbClass_selected" : '//*[@id="oj-listbox-results-dbClass"]/li/div[not (@aria-disabled)]',
    "ojChoiceId_dbStorage_selected" : '//*[@id="oj-listbox-results-dbStorage"]/li/div[not (@aria-disabled)]',
    "ojChoiceId_dbCharset_selected" : '//*[@id="oj-listbox-results-dbCharset"]/li/div',
    "ojChoiceId_dbNlsCharset_selected" : '//*[@id="oj-listbox-results-dbNlsCharset"]/li/div',
    "ojChoiceId_dbLanguage_selected" : '//*[@id="oj-listbox-results-dbLanguage"]/li/div',
    "ojChoiceId_dbTerritory_selected" : '//*[@id="oj-listbox-results-dbTerritory"]/li/div'}
"""
driver1 = cm.driver1


def input_db(x="adminPwd", y="cpadminPwd", dbhome=False, db1=dbName, driver=driver1):
    cm.by_id_input("dbName", db1, driver)
    cm.by_id_input("dbUniqueName", dbUniqueName, driver)
    # for key, value in dbName_text_box.items():
    #    cm.by_id_input(key, value)
    # for key, value in db_choice.items():
    # cm.option_random_choice(key, value)
    if dbhome:
        cm.by_id_click("existingDbHome", driver)
        cm.option_random_choice("oj-select-choice-dbHome",'//*[@id="oj-listbox-results-dbHome"]/li/div', driver)
    else:
        cm.option_random_choice("ojChoiceId_dbVersion_selected",
                                '//*[@id="oj-listbox-results-dbVersion"]/li/div[not (@aria-disabled)]', driver)
        cm.option_random_choice("ojChoiceId_dbEdition_selected", '//*[@id="oj-listbox-results-dbEdition"]/li/div', driver)
    cm.option_random_choice("oj-select-choice-dbShape", '//*[@id="oj-listbox-results-dbShape"]/li/div', driver)
    cm.option_random_choice("ojChoiceId_dbClass_selected",
                            '//*[@id="oj-listbox-results-dbClass"]/li/div[not (@aria-disabled)]', driver)
    cm.option_random_choice("ojChoiceId_dbStorage_selected",
                            '//*[@id="oj-listbox-results-dbStorage"]/li/div[not (@aria-disabled)]', driver)
    cm.option_random_choice("ojChoiceId_dbCharset_selected", '//*[@id="oj-listbox-results-dbCharset"]/li/div', driver)
    cm.option_random_choice("ojChoiceId_dbNlsCharset_selected", '//*[@id="oj-listbox-results-dbNlsCharset"]/li/div', driver)
    cm.option_random_choice("ojChoiceId_dbLanguage_selected", '//*[@id="oj-listbox-results-dbLanguage"]/li/div', driver)
    cm.option_random_choice("ojChoiceId_dbTerritory_selected", '//*[@id="oj-listbox-results-dbTerritory"]/li/div', driver)

    if cm.is_element_exist_by_id("yesCdb", driver):
        input_cdb_info(driver)
    if cm.is_element_exist_by_id("ojChoiceId_dbType_selected", driver):
        cm.option_random_choice("ojChoiceId_dbType_selected", '//*[@id="oj-listbox-results-dbType"]/li/div', driver)
    if cm.is_element_exist_by_id("nodeNumber0", driver):
        choose_option(node_list, driver)
    if cm.is_element_exist_by_id("yesFlash", driver):
        choose_option(flash_list, driver)

    cm.by_id_click(EmConsole, driver)
    cm.by_id_input(x, password2, driver)
    cm.by_id_input(y, password2, driver)


def input_cdb_info(driver=driver1):
    cdb = random.choice(["yesCdb", "noCdb"])
    # cdb = random.choice(["yesCdb"])

    cm.by_id_click(cdb, driver)
    if cdb == "yesCdb":
        for key, value in pdbName_text_box.items():
            cm.by_id_input(key, value, driver)


def choose_option(x, driver=driver1):
    a = random.choice(x)
    cm.by_id_click(a, driver)


