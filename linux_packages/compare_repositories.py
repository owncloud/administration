#!/usr/bin/env python3
'''
Very basic owncloud-client linux repository dependencies comparison:
    - motivation: https://github.com/owncloud/platform/issues/81
@author: Samuel Alfageme (samuel@owncloud.com)

 - Inputs: 2 *local* repositories, a list of valid linux distributions. e.g. 
        distros = ["Ubuntu_14.04","Ubuntu_16.04"]
        repoA = '/home/user/owncloud-client'
        repoB = '/home/user/owncloud-client-new'

        Note: It would be desirable to include repositories via url.

 - Outputs: A json response with the contents of diffing owncloud-client 
       dependencies. e.g.

        { 
            "Ubuntu_14.04": {
                "repoA": ["libqt5core5a (>= 5.5.0)", "libqt5webkit5 (>= 5.0.2)"],
                "repoB": ["libqt5core5a (>= 5.6.0~beta)", "libqt5webkit5 (>= 5.6.0~rc)"]
            },
            "Ubuntu_16.04": {
            ...
        }
'''
from os import path
import filecmp
import json

# FIXME: replace this hardcoded test paths for optparse variables:

# Local repositories will be positional arguments at the end
#repoA = "./testpilotcloud-client-2.2.4-20160927"
#repoB = "./owncloud-client-2.2.4-20170104"

# Distros will be preceded by -d Ubuntu_14.04,Ubuntu_16.04
#distros = ["Ubuntu_14.04","Ubuntu_16.04","Fedora_24"]

from optparse import OptionParser

parser = OptionParser()

parser.add_option("-d", "--distributions",
                    help="Specify the Linux distributions for which the comparison should be made, sepparated by commas.")

(options, args) = parser.parse_args()

distros = options.distributions.split(",") 

repoA, repoB = args

shortnameA, shortnameB = path.basename(repoA), path.basename(repoB)

if not (path.exists(repoA) and path.exists(repoB)):
    raise ValueError("The repository paths are not valid.")
elif not set(distros).issubset(set(filecmp.dircmp(repoA,repoB).common_dirs)):
    raise ValueError("The Linux distributions specified are not present in both repositories.") 
else:
    results = {distro:{shortnameA:[],shortnameB:[]} for distro in distros}
    for distro in distros:
        if distro[0] == 'U' or distro[0] == 'D': 
            # Ubuntu, Debian
            opt = "amd64"
        else:
            # Centos, Fedora, SUSE 
            opt = "x86_64"

        diff = filecmp.dircmp(path.join(repoA,distro,opt),path.join(repoB,distro,opt))

        results[distro][shortnameA] = diff.left_only
        results[distro][shortnameB] = diff.right_only

    print(json.dumps(results, indent=4))

