"""
This script includes "User and Group Selection" elements on UI page
"""

import random
import string
import ui_common_method as cm



def gen_random_string_letter():
    return ''.join(random.sample(string.ascii_letters, random.randint(1, 10)))

def gen_random_digits():
    return ''.join(random.sample(string.digits, random.randint(1, 10)))


# def gen_random_digits():
    # chars = string.digits
    # length = random.randint(1, 10)
    # return ''.join([random.choice(chars) for i in range(length)])


OsRole = random.choice(["yesOsRole", "noOsRole"])
giUser = gen_random_string_letter()
giUserId = gen_random_digits()
dbUser = gen_random_string_letter()
dbUserId = gen_random_digits()
installGroup = gen_random_string_letter()
installGroupId = gen_random_digits()
dbaOperGroup = gen_random_string_letter()
dbaOperGroupId = gen_random_digits()
dbaGroup = gen_random_string_letter()
dbaGroupId = gen_random_digits()
asmAdminGroup = gen_random_string_letter()
asmAdminGroupId = gen_random_digits()
asmOperGroup = gen_random_string_letter()
asmOperGroupId = gen_random_digits()
asmDbaGroup = gen_random_string_letter()
asmDbaGroupId = gen_random_digits()

yesOsRole_text_box = {
    "giUser": "%s" % giUser,
    "giUserId": "%s" % giUserId,
    "dbUser": "%s" % dbUser,
    "dbUserId": "%s" % dbUserId,
    "installGroup": "%s" % installGroup,
    "installGroupId": "%s" % installGroupId,
    "dbaOperGroup": "%s" % dbaOperGroup,
    "dbaOperGroupId": "%s" % dbaOperGroupId,
    "dbaGroup": "%s" % dbaGroup,
    "dbaGroupId": "%s" % dbaGroupId,
    "asmAdminGroup": "%s" % asmAdminGroup,
    "asmAdminGroupId": "%s" % asmAdminGroupId,
    "asmOperGroup": "%s" % asmOperGroup,
    "asmOperGroupId": "%s" % asmOperGroupId,
    "asmDbaGroup": "%s" % asmDbaGroup,
    "asmDbaGroupId": "%s" % asmDbaGroupId}

noOsRole_text_box = {
    "dbUser": "%s" % dbUser,
    "dbUserId": "%s" % dbUserId,
    "installGroup": "%s" % installGroup,
    "installGroupId": "%s" % installGroupId,
    "dbaOperGroup": "%s" % dbaOperGroup,
    "dbaOperGroupId": "%s" % dbaOperGroupId,
    "dbaGroup": "%s" % dbaGroup,
    "dbaGroupId": "%s" % dbaGroupId,
    "asmAdminGroup": "%s" % asmAdminGroup,
    "asmAdminGroupId": "%s" % asmAdminGroupId,
    "asmOperGroup": "%s" % asmOperGroup,
    "asmOperGroupId": "%s" % asmOperGroupId,
    "asmDbaGroup": "%s" % asmDbaGroup,
    "asmDbaGroupId": "%s" % asmDbaGroupId}


def input_custom_user():
    cm.by_id_click("%s" % OsRole)
    if OsRole == "yesOsRole":
        for key, value in yesOsRole_text_box.items():
            cm.by_id_input(key, value)

    elif OsRole == "noOsRole":
        for key, value in noOsRole_text_box.items():
            cm.by_id_input(key, value)
