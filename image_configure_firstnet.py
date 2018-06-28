#!/user/bin/env python
#conding utf-8

"""
Usage:
    image_configure_firsnet.py  -s <servername> -v <version> [-u <username>] [-p <password>] [--vm]

Options:
    -h,--help       Show this help message
    -s <servername>   hostname of machine
    -v <version>   the version you want to re-image to
    -u <username>   username [default: root]
    -p <password>   password [default: welcome1]
    --vm   image to vm stack
"""

import image
import configure_firstnet
from docopt import docopt
import oda_lib
import deploy_patch_patch as d_p_p
import common_fun as cf
import sys
import time

def main(arg):
    hostname = arg['-s']
    version = arg['-v']
    password = arg['-p']
    username = arg['-u']
    vm = arg["--vm"]
    logfile_name = 'Image_firstnet_provision_patch_%s.log' % hostname
    fp, out, err,log = cf.logfile_name_gen_open(logfile_name)
    image.cleanup(hostname, username, password)
    sys.stdout.flush()
    time.sleep(300)
    print "Will image the host %s" % hostname
    sys.stdout.flush()
    image.image(hostname, version, vm)
    ips = configure_firstnet.configure_firstnet(hostname, version, vm)
    print "Finish configure firstnet, you can use the following ip to configure:"
    print ips
    sys.stdout.flush()
    if not configure_firstnet.is_dcs(hostname, version):
        print "This host is OAK stack, please continue to deploy to %s manually!" % (hostname, version)
        sys.stdout.flush()
    else:
        print "Will do the provision and patch to latest version!"
        sys.stdout.flush()
        host = oda_lib.Oda_ha(ips[0], "root", "welcome1")
        d_p_p.provision_patch(host)
        sys.stdout.flush()
    cf.closefile(fp, out, err)
    print "Done, please check the log %s for details!" % log


if __name__ == '__main__':
    arg = docopt(__doc__)
    print arg
    main(arg)