#!/bin/bash
# 

useradd jenkins --uid $1
shift

zypper mr -d http://download.opensuse.org/repositories/windows:/mingw/openSUSE_42.1
# 2017-09-10, jw: the main 42.1 repos are removed from OBS. Only 'OSS Update' remains.
zypper mr -d OSS
zypper mr -d NON-OSS
zypper mr -d 'OSS Update'

# Not needed. sudo is already onboard in alfageme/docker-owncloud-client-win32
# zypper --non-interactive --gpg-auto-import-keys install sudo

zypper --non-interactive --gpg-auto-import-keys ar http://download.opensuse.org/repositories/isv:/ownCloud:/toolchains:/mingw:/win32:/2.3.4/openSUSE_Leap_42.1/isv:ownCloud:toolchains:mingw:win32:2.3.4.repo
zypper refresh -f
# hack for https://kanboard.owncloud.com/project/1/task/1772
zypper --non-interactive install mingw32-libopenssl-devel=1.0.2n mingw32-libopenssl-devel=1.0.2n

# hack for https://github.com/owncloud/client/issues/5950
zypper --non-interactive install mingw32-cross-nsis=3.01

## not no permissions in nsis3_compat_hack.sh:
cp /usr/share/nsis/Plugins/UAC.dll /usr/share/nsis/Plugins/x86-ansi/
cp /usr/share/nsis/Plugins/UAC.dll /usr/share/nsis/Plugins/x86-unicode/
cp /usr/share/nsis/Plugins/nsProcess.dll /usr/share/nsis/Plugins/x86-ansi/
cp /usr/share/nsis/Plugins/nsProcess.dll /usr/share/nsis/Plugins/x86-unicode/
# end of hack
 
sudo -u jenkins $(dirname ${BASH_SOURCE[0]})/compile_client.sh $@

