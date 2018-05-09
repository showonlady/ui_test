"""
This script includes "System Information" and "Network Information" elements on UI page

"""
import random
import string
import ui_common_method as cm

# System Information
hostnodeName = ""
domainName = "us.oracle.com"

dnsTextGroup1 = "10.209.76.197"
dnsTextGroup2 = "10.209.76.198"
dnsTextGroup3 = "192.135.82.132"
ntpTextGroup = "152.68.120.1"
dataStorage = random.randint(10, 90)
password = "WElcome12-_"
cpassword = "WElcome12-_"

system_text_box = {
    "domainName": "%s" % domainName,
    "dataStorage": "%s" % dataStorage,
    "password": "%s" % password,
    "cpassword": "%s" % cpassword}

system_text_boxes = {
    "//*[@id='dnsTextGroup']/div/div[1]/input": "%s" % dnsTextGroup1,
    "//*[@id='dnsTextGroup']/div/div[2]/input": "%s" % dnsTextGroup2,
    "//*[@id='dnsTextGroup']/div/div[3]/input": "%s" % dnsTextGroup3,
    "//*[@id='ntpTextGroup']/div/div[1]/input": "%s" % ntpTextGroup}

# ILOM Network Information
###rwsoda6m005
ilomName_6m005 = "rwsoda6m005-c"
ilomIp_6m005 = "10.209.8.223"
oj_select_choice_ilomSubnet_6m005 = "255.255.254.0"
ilomGateway_6m005 = "10.209.8.1"
ilom_network_info = {
    "ilomName": "%s" % ilomName_6m005,
    "ilomIp": "%s" % ilomIp_6m005,
    "ilomGateway": "%s" % ilomGateway_6m005
}

####scaoda704c1n1
scaoda704_public_network_info = {
    "hostName" : "scaoda704c1n1",
    "hostName1" : "scaoda704c1n2",
    "ipAutoPublic1" : "10.31.97.117",
    "vipName0" : "scaoda704c1n1-vip",
    "vipPublic0" : "10.31.97.142",
    "vipName1" : "scaoda704c1n2-vip",
    "vipPublic1" : "10.31.97.143",
    "scanName" : "scaoda704c1-scan",
    "scanIpPublic1" : "10.31.97.166",
    "scanIpPublic2" : "10.31.97.167",
    "ilomName" : "scaoda7041-c",
    "ilomIp" : "10.31.16.135",
    "ilomName1" : "scaoda7042-c",
    "ilomIp1" : "10.31.16.136",
    "ilomGateway" : "10.31.16.1"
}
ilom_submet_scaoda704 = "255.255.240.0"

scaoda704_vlan_public_network_info = {
    "hostName" : "scaoda704c1n1",
    "hostName1" : "scaoda704c1n2",
    "ipAutoPublic1" : "10.31.130.37",
    "vipName0" : "scaoda704c1n1-vip",
    "vipPublic0" : "10.31.130.38",
    "vipName1" : "scaoda704c1n2-vip",
    "vipPublic1" : "10.31.130.39",
    "scanName" : "scaoda704c1-scan",
    "scanIpPublic1" : "10.31.130.40",
    "scanIpPublic2" : "10.31.130.41",
    "ilomName" : "scaoda7041-c",
    "ilomIp" : "10.31.16.135",
    "ilomName1" : "scaoda7042-c",
    "ilomIp1" : "10.31.16.136",
    "ilomGateway" : "10.31.16.1"
}

## rwsoda6s005
ipPublic_6s005 = "10.209.13.108"
ojChoiceId_subnetPublic_selected_6s005 = "255.255.252.0"
ojChoiceId_nicNamePublic_selected_6s005 = "btbond1"

network_dropdown_6s005 = {
    "ojChoiceId_subnetPublic_selected":
        "//*[text() = '%s']" % ojChoiceId_subnetPublic_selected_6s005,
    "ojChoiceId_nicNamePublic_selected":
        "//*[text() = '%s']" % ojChoiceId_nicNamePublic_selected_6s005}

## scaoda7m005
ipPublic_7m005 = "10.31.101.109"
ojChoiceId_subnetPublic_selected_7m005 = "255.255.240.0"

## scaoda710c1n1/2
hostName_710 = "scaoda710c1n1"
ipPublic_710 = "10.31.99.176"
hostName1_710 = "scaoda710c1n2"
ipPublic1_710 = "10.31.99.177"
ojChoiceId_subnetPublic_selected_710 = "255.255.240.0"
vipName0_710 = "scaoda710c1n1-vip"
vipPublic0_710 = "10.31.99.202"
vipName1_710 = "scaoda710c1n2-vip"
vipPublic1_710 = "10.31.99.203"
scanName_710 = "scaoda710c1-scan"
scanIpPublic1_710 = "10.31.99.226"
scanIpPublic2_710 = "10.31.99.227"

network_text_box_710 = {
    "hostName": "%s" % hostName_710,
    "ipPublic": "%s" % ipPublic_710,
    "hostName1": "%s" % hostName1_710,
    "ipPublic1": "%s" % ipPublic1_710,
    "vipName0": "%s" % vipName0_710,
    "vipPublic0": "%s" % vipPublic0_710,
    "vipName1": "%s" % vipName1_710,
    "vipPublic1": "%s" % vipPublic1_710,
    "scanName": "%s" % scanName_710,
    "scanIpPublic1": "%s" % scanIpPublic1_710,
    "scanIpPublic2": "%s" % scanIpPublic2_710}


def input_system_network(node):
    if node in ["rwsoda6s005", "scaoda7m005", "rwsoda6f004", "rwsoda6m005", "scaoda7s005"]:
        cm.by_id_input("hostnodeName", "%s" % node)
    if node in ["scaoda710c1n", "scaoda704c1n"]:
        cm.by_id_input("systemName", "%s" % node)
    if node in ["10.31.129.245"]:
        cm.by_id_input("hostnodeName", "scaoda7s005" )
    if node in ["10.31.130.36"]:
        cm.by_id_input("systemName", "scaoda704c1n1")
    for key, value in system_text_box.items():
        cm.by_id_input(key, value)
    cm.option_random_choice("ojChoiceId_region_selected",
                            '//*[@id="oj-listbox-results-region"]/li/div')
    cm.option_random_choice("ojChoiceId_timezone_selected", '//*[@id="oj-listbox-results-timezone"]/li/div')
    if cm.is_element_exist_by_id("ojChoiceId_dgRedundancy_selected"):
        cm.option_random_choice("ojChoiceId_dgRedundancy_selected", '//*[@id="oj-listbox-results-dgRedundancy"]/li/div')
    if node not in ["10.31.130.36","10.31.129.245"]:
        for key, value in system_text_boxes.items():
            cm.by_xpath_input(key, value)

    if node == "rwsoda6m005":
        for key, value in ilom_network_info.items():
            cm.by_id_input(key, value)
        cm.by_id_select("oj-select-choice-ilomSubnet", "//*[text() = '%s']" % oj_select_choice_ilomSubnet_6m005)
    if node == "scaoda704c1n":
        for key, value in scaoda704_public_network_info.items():
            cm.by_id_input(key, value)
        cm.by_xpath_select('//*[@id="ilomSubnetDiv_0"]/div[2]/div[1]','//*[text() = "%s"]' % ilom_submet_scaoda704)
    if node == "10.31.130.36":
        for key, value in scaoda704_vlan_public_network_info.items():
            cm.by_id_input(key, value)
        cm.by_xpath_select('//*[@id="ilomSubnetDiv_0"]/div[2]/div[1]','//*[text() = "%s"]' % ilom_submet_scaoda704)

    if node == "rwsoda6s005":
        cm.by_id_input("ipPublic", "%s" % ipPublic_6s005)
        for key, value in network_dropdown_6s005.items():
            cm.by_id_select(key, value)
    elif node == "scaoda7m005":
        cm.by_id_input("ipPublic", "%s" % ipPublic_7m005)
        cm.by_id_select("ojChoiceId_subnetPublic_selected",
                        "//*[text() = '%s']" % ojChoiceId_subnetPublic_selected_7m005)
    elif node == "scaoda710c1n":
        for key, value in network_text_box_710.items():
            cm.by_id_input(key, value)
        cm.by_id_select("ojChoiceId_subnetPublic_selected",
                        "//*[text() = '%s']" % ojChoiceId_subnetPublic_selected_710)
