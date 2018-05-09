"""
This script includes ASR elements on UI page

"""
import random
import base64
import ui_common_method as cm

ojChoiceId_asrType_selected = random.choice(["INTERNAL", "EXTERNAL"])
asrUserName = "chunling.qin@oracle.com"
asrPassword = base64.b64decode('VzJTc2hvd29uMQ==')
ojChoiceId_snmpVersion_selected = random.choice(["v2", "v3"])
asrManagerIp = "192.168.1.1"
Proxy = "yesProxy"
proxyHostName = "www-proxy.us.oracle.com"
proxyPort = 80

asr_text_box = {
    "asrUserName": "%s" % asrUserName,
    "asrPassword": "%s" % asrPassword,
    "proxyHostName": "%s" % proxyHostName,
    "proxyPort": "%s" % proxyPort}

asr_dropdown_lists = {
    "ojChoiceId_asrType_selected": "//*[text() = '%s']" % ojChoiceId_asrType_selected,
    "ojChoiceId_snmpVersion_selected": "//*[text() = '%s']" % ojChoiceId_snmpVersion_selected}


def config_asr():
    for key, value in asr_dropdown_lists.items():
        cm.by_id_select(key, value)
    if ojChoiceId_asrType_selected == "INTERNAL":
        cm.by_id_click("%s" % Proxy)
        for key, value in asr_text_box.items():
            cm.by_id_input(key, value)
    elif ojChoiceId_asrType_selected == "EXTERNAL":
        cm.by_id_input("asrManagerIp", "%s" % asrManagerIp)
