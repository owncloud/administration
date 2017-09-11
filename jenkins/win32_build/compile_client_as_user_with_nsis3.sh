#!/bin/bash
# 

useradd jenkins --uid $1
shift
zypper mr -d http://download.opensuse.org/repositories/windows:/mingw/openSUSE_42.1
zypper --non-interactive --gpg-auto-import-keys install sudo

# hack for https://github.com/owncloud/client/issues/5950
zypper --non-interactive --gpg-auto-import-keys ar http://download.opensuse.org/repositories/isv:/ownCloud:/toolchains:/mingw:/win32:/2.3.3/openSUSE_Leap_42.1/isv:ownCloud:toolchains:mingw:win32:2.3.3.repo
zypper refresh -f && zypper --non-interactive install mingw32-cross-nsis=3.01
ln -s ../UAC.dll ../nsProcess.dll /usr/share/nsis/Plugins/x86-ansi/
ln -s ../UAC.dll ../nsProcess.dll /usr/share/nsis/Plugins/x86-unicode/
# end of hack
 
sudo -u jenkins $(dirname ${BASH_SOURCE[0]})/compile_client.sh $@

