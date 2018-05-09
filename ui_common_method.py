import time
import random
import string
from selenium import webdriver
from selenium.webdriver.common.by import By
import selenium.webdriver.support.ui as ui
from selenium.webdriver.support import expected_conditions as ec

driver1 = webdriver.Chrome()


def by_id_input(i, j, driver=driver1):
    driver.find_element_by_id(i).clear()
    driver.find_element_by_id(i).send_keys(j)


def by_xpath_input(i, j, driver=driver1):
    driver.find_element_by_xpath(i).clear()
    driver.find_element_by_xpath(i).send_keys(j)


def by_id_select(i, j, driver=driver1):
    driver.find_element_by_id(i).click()
    driver.find_element_by_xpath(j).click()


def by_xpath_select(i, j, driver=driver1):
    driver.find_element_by_xpath(i).click()
    driver.find_element_by_xpath(j).click()


def by_id_click(i, driver=driver1):
    driver.find_element_by_id(i).click()


def merge_dicts(*dict_args):
    result = {}
    for dictionary in dict_args:
        result.update(dictionary)
    return result


def option_random_choice(i, j, driver=driver1):
    by_id_click(i, driver)
    #time.sleep(1)
    a = driver.find_elements_by_xpath(j)
    if len(a) != 0:
        random.choice(a).click()
    else:
        return False


def is_element_exist_by_id(x, driver=driver1):
    a = driver.find_elements_by_id(x)
    if len(a) == 0:
        return False
    else:
        return True


def gen_random_string(x, y):
    length = random.randint(1, y)
    start_char = random.choice(string.ascii_letters)
    chars = ''.join(random.sample(x, random.randint(0, length - 1)))
    random_string = start_char + chars
    return random_string
