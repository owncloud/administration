#!/bin/bash

#================================================================================
#
#         FILE:  makewinlin.sh
#
#        USAGE:  makewinlin.sh [-b, --build-environment]
#                              [-d, --dependencies]
#                              [-do, --dependencies-only]
#                              [-h, --help, --man]
#                              [-i, --interactive]
#                              [-le --local-environment]
#                              [-lin, --linux]
#                              [-nc, --no-customizations]
#                              [-gc, --garbageclean]
#                              [-s, --sign]
#                              [-so, --sign-only]
#                              [-win, --windows]
#
#  DESCRIPTION:  Build the ownCloud clients for Windows and Linux
# KNOWN ISSUES:  Run as sudo to build Linux clients
# REQUIREMENTS:  OpenSUSE 13.2 64 bit
#       AUTHOR:  Koen Willems
#                Sendin B.V. <info at sendin.nl>
#      VERSION:  1.0.0
#      CREATED:  August 10, 2014
#
#================================================================================

#================================================================================
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
#  for more details.
#
#================================================================================



CUR_DIR=$PWD
BUILD_DIR="${CUR_DIR}/buildenv"
OSLINUX=1



#================================================================================
#
#        NAME: code section
# DESCRIPTION: Source config and library.
#              If one of them is not available the script will stop.
#
#================================================================================

if ! source config ; then
    echo $'\nThe file \"config\" is not available; we\'ll quit.\n'
    exit 1
fi

if ! source library ; then
    echo $'\nThe file \"library\" is not available; we\'ll quit.\n'
    exit 1
fi



#================================================================================
#
#        NAME: buildLinuxDependencies
# DESCRIPTION: Build dependencies.
#              If DEPENDENCIES=1 the script stops here.
#
#================================================================================

function buildLinuxDependencies() {
    if [ ${DEPENDENCIES} -eq 1 ] ; then

        #sudo zypper --gpg-auto-import-keys addrepo http://download.opensuse.org/repositories/isv:ownCloud:devel/openSUSE_13.2/isv:ownCloud:devel.repo
        sudo zypper --gpg-auto-import-keys addrepo http://download.opensuse.org/repositories/isv:ownCloud:desktop/openSUSE_13.2/isv:ownCloud:desktop.repo

        sudo zypper --gpg-auto-import-keys addrepo http://download.opensuse.org/repositories/windows:/mingw:/win32/openSUSE_13.2/windows:mingw:win32.repo
        sudo zypper --gpg-auto-import-keys addrepo http://download.opensuse.org/repositories/windows:/mingw/openSUSE_13.2/windows:mingw.repo

        sudo zypper --gpg-auto-import-keys refresh
        sudo zypper -n install owncloud-client
        sudo zypper refresh
        sudo zypper -n --gpg-auto-import-keys source-install -d owncloud-client

        sudo zypper install git cmake mingw32-cross-binutils \
            mingw32-cross-gcc mingw32-cross-gcc-c++ mingw32-cross-pkg-config \
            mingw32-libneon-openssl-devel mingw32-sqlite-devel mingw32-libqt5-qmldevtools-devel \
            mingw32-libqt5-qtimageformats-devel mingw32-libqt5-qtbase-devel mingw32-libqt5-qtwinextras-devel \
            mingw32-libqt5-qtsvg-devel mingw32-libqt5-qtsensors-devel mingw32-libqt5-qtserialport-devel \
            mingw32-libqt5-qtxmlpatterns-devel mingw32-libqt5-qtmultimedia-devel mingw32-qt5keychain-devel \
            mingw32-cross-libqt5-qmake kdewin-png2ico mingw32-cross-nsis \
            mingw32-libqt5-qtimageformats mingw32-libqt5-qtsvg mingw32-libqt5-qtwebkit \
            mingw32-libqt5-qttools mingw32-libqt5-qttranslations mingw32-cross-libqt5-qttools \
            mingw32-angleproject-devel mingw32-qt5keychain mingw32-libneon-openssl mingw32-libwinpthread1 \
            osslsigncode mingw32-qtkeychain \

        #
        # The following is not really needed.
        #
        #sudo zypper -n install mingw32-cmocka-devel texlive-latex python-sphinx

        #
        # The following will work on openSUSE 12.2, 13.1 and 13.2 too.
        #
        sudo rpm --nosignature -i http://download.tomahawk-player.org/packman/mingw:32/openSUSE_12.1/x86_64/mingw32-cross-nsis-plugin-processes-0-1.1.x86_64.rpm
        sudo rpm --nosignature -i http://download.tomahawk-player.org/packman/mingw:32/openSUSE_12.1/x86_64/mingw32-cross-nsis-plugin-uac-0-3.1.x86_64.rpm

        echo $'\nAll dependencies, libraries and other necessary thingies should be installed now.\n'

        if [ ${DEPENDENCIES_ONLY} -eq 1 ] ; then
            exit 0
        fi
    fi
}



#================================================================================
#
#        NAME: buildWindowsClient
# DESCRIPTION: Build and package Windows client.
#              If finished copy EXE to the folder client.
#              Remove "0-setup" out of filename, depending on the value of CHANGENAME.
#
#================================================================================

function buildWindowsClient() {
    if [ ${LINUX_ONLY} -eq 0 ] ; then
        mkdir -p windows/mirall-build
        cd windows/mirall-build

        source "${BUILD_DIR}"/mirall/admin/win/download_runtimes.sh

        ownThemeDir=""
        if [ ${OWNTHEME} -eq 1 ] ; then
            ownThemeDir="-DOEM_THEME_DIR=${BUILD_DIR}/mirall/mytheme"
        fi

        cmake -DCMAKE_BUILD_TYPE="Debug" ../../mirall \
            -DCMAKE_TOOLCHAIN_FILE=../../mirall/admin/win/Toolchain-mingw32-openSUSE.cmake \
            ${ownThemeDir}

        pause

        make
        make package

        if [ ${CHANGENAME} -eq 1 ] ; then
            for file in *.exe
            do
                mv "$file" "${file%%.0-setup.exe}.exe"
            done
        fi

        # This is rickety coding; have to look at it
        for file in *.exe
        do
            cp "${BUILD_DIR}"/windows/mirall-build/*.exe "${CUR_DIR}"/client
        done

        cd "${CUR_DIR}"/client
        for file in vcredist*
        do
            rm ${file}
        done

        cd ${BUILD_DIR}
        signEXE
    fi
}



#================================================================================
#
#        NAME: buildLinuxClient
# DESCRIPTION: Build and package Windows client.
#              If finished copy files to folder client.
#
#================================================================================

function buildLinuxClient() {
    if [ ${WINDOWS_ONLY} -eq 0 ] ; then

        #
        # When compiling for Linux the executable should be called 'owncloud'
        # So OWNCLOUD.cmake is overwritten by another version if CUSTOMIZE=1
        # and the file is available.
        #
        if [ ${CUSTOMIZE} -eq 1 ] ; then
            if [ -f ./buildenv/mirall/mytheme/OEM_linux.cmake ] ; then
                cd "${CUR_DIR}"
                cp ./buildenv/mirall/mytheme/OEM_linux.cmake ./buildenv/mirall/mytheme/OEM.cmake
            fi
        fi

        cd "${BUILD_DIR}"
        mkdir -p linux/mirall-build
        cd linux/mirall-build

        cmake -DCMAKE_BUILD_TYPE="Debug" ../../mirall

        pause

        make
        make package

        cd ${BUILD_DIR}
        cp "${BUILD_DIR}"/linux/mirall-build/*mirall-*Linux.* "${CUR_DIR}"/client
    fi
}



#================================================================================
#
#        NAME: signEXE
# DESCRIPTION: Code sign the EXE
#              Runs when CODESIGN=1, pathCodeSignCertificate exists and
#              is longer than 0 and the certificate is present at the given location.
#              Furthermore, it is highly recommended to time stamp the EXE.
#
#================================================================================

function signEXE() {
    if [ ${CODESIGN} -eq 1 ] ; then
        if [ -n "${pathCodeSignCertificate}" ] ; then
            if [ -f "${pathCodeSignCertificate}" ] ; then
                echo
                echo
                read -s -p "Enter the password of your private key: " password
                echo

                cd "${CUR_DIR}"/client
                for file in *.exe
                do
                    fileNameLong=${file}
                    fileNameShort=${file%.exe}

                        if [  -n "${serverTimeStamp}" ] ; then
                            osslsigncode -pkcs12 "${pathCodeSignCertificate}" -pass "$password" \
                                -n "${fileNameShort}" -i "${infoURL}" \
                                -t "${serverTimeStamp}" \
                                -in "${fileNameLong}" -out signed_"${fileNameLong}"
                        else
                            osslsigncode -pkcs12 "${pathCodeSignCertificate}" -pass "$password" \
                                -n "${fileNameShort}" -i "${infoURL}" \
                                -in "${fileNameLong}" -out signed_"${fileNameLong}"
                        fi
                done
                cd ${BUILD_DIR}
            else
                echo $'\nCould not find a certificate, so nothing is code signed.\n'
            fi
        else
            echo $'\nThere\'s no path and certificate name entered in \"config\", so nothing is code signed.\n'
        fi
    fi
}



#================================================================================
#
#        NAME: checkSignEXEOnly
# DESCRIPTION: If CODESIGN_ONLY=1 the script will stop after code signing.
#
#================================================================================

function checkSignEXEOnly() {
    if [ "${CODESIGN_ONLY}" -eq 1 ] ; then
        signEXE
        exit 0
    fi
}



#================================================================================
#
#        NAME: checkMachine
# DESCRIPTION: Check if this is a 64 bit machine.
#
#================================================================================

function checkMachine() {
    if [ $(uname -m) != "x86_64" ] ; then
        echo $'\nYou\'d better use a 64 bit machine. Quitting now.\n'
        exit 1
    fi
}



#================================================================================
#
#        NAME: code section
# DESCRIPTION: Run run run ...
#
#================================================================================

checkMachine
checkHelp
checkSignEXEOnly
buildLinuxDependencies
makeBuildEnv
grabMirall
buildCustomizations
buildWindowsClient
buildLinuxClient
cleanBuildGarbage
showMessage



#================================================================================
#
#        NAME: code section
# DESCRIPTION: Leave
#
#================================================================================

exit 0