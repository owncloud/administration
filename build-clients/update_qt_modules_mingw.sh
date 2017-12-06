#!/bin/bash
 
set -e
set -x
 
CONFIG_ARCH='32'
CONFIG_OLD_VERSION='5.6.2'
CONFIG_NEW_VERSION='5.9.3'
 
CONFIG_OLD_WEBKIT_VERSION='5.6.2'
CONFIG_NEW_WEBKIT_VERSION='5.9.0'
 
 
# unused: connectivity enginio graphicaleffects imageformats location quick1 quickcontrols script serialport websockets winextras
for QTMODULE in base declarative multimedia sensors svg tools translations webkit xmlpatterns
do
    if [ "${QTMODULE}" == "webkit" ]; then
        OLD_VERSION="${CONFIG_OLD_WEBKIT_VERSION}"
        NEW_VERSION="${CONFIG_NEW_WEBKIT_VERSION}"
        NEW_FILE="qt${QTMODULE}-opensource-src-${NEW_VERSION}.tar.xz"
        DOWNLOAD_URL="http://download.qt.io/community_releases/${NEW_VERSION:0:3}/${NEW_VERSION}-final/${NEW_FILE}"
    else
        OLD_VERSION="${CONFIG_OLD_VERSION}"
        NEW_VERSION="${CONFIG_NEW_VERSION}"
        NEW_FILE="qt${QTMODULE}-opensource-src-${NEW_VERSION}.tar.xz"
        DOWNLOAD_URL="http://download.qt.io/archive/qt/${NEW_VERSION:0:3}/${NEW_VERSION}/submodules/${NEW_FILE}"
    fi
    ARCH="${CONFIG_ARCH}"
 
 
    PACKAGE_NAME="mingw${ARCH}-libqt5-qt${QTMODULE}"
    echo "Update: ${PACKAGE_NAME}"
    if [ ! -d "${PACKAGE_NAME}" ]; then
        osc co "${PACKAGE_NAME}"
    fi
    pushd "${PACKAGE_NAME}"
 
    osc up
 
    OLD_FILE="qt${QTMODULE}-opensource-src-${OLD_VERSION}.tar.xz"
    if [ -f "${OLD_FILE}" ]; then
        osc rm "${OLD_FILE}"
    fi
 
    wget -c "${DOWNLOAD_URL}"
 
    osc add "${NEW_FILE}"
 
    popd
done

