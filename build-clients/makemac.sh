#!/bin/bash

#================================================================================
#
#         FILE:  makemac.sh
#
#        USAGE:  makemac.sh [-b, --build-environment]
#                           [-d, --dependencies]
#                           [-do, --dependencies-only]
#                           [-h, --help | --man]
#                           [-i, --interactive]
#                           [-le --local-environment]
#                           [-nc, --no-customizations]
#                           [-gc, --garbageclean]
#                           [-s, --sign]
#                           [-so, --sign-only]
#                           [-sp, --sparkle]
#                           [-spo, --sparkle-only]
#
#  DESCRIPTION:  Build the ownCloud client for MAC
#
# REQUIREMENTS:  OS X 10.9
#                XCode (with command line tools)
#                Homebrew, see http://brew.sh/
#                Packages, see http://s.sudre.free.fr/Software/Packages/about.html
#                Sparkle, see http://sparkle-project.org/ (optional)
#
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
OSLINUX=0
PATH=/usr/local/Cellar/qt5/5.3.2/bin:$PATH



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
#        NAME: code section
# DESCRIPTION: Simple check if 'Packages' is installed.
#              If packagesutil and/or packagesbuild are not present the script
#              assumes Packages is not installed.
#
#================================================================================

if [ ! -f /usr/local/bin/packagesutil ] || [ ! -f /usr/local/bin/packagesbuild ] ; then
	echo
	echo 'You have to install "Packages", see "http://s.sudre.free.fr/Software/Packages/about.html".'
	echo
	exit 1
fi



#================================================================================
#
#        NAME: buildMacDependencies
# DESCRIPTION: Build dependenecies.
#              If DEPENDENCIES_ONLY=1 the script stops here.
#
#================================================================================

function buildMacDependencies() {
    if [ ${DEPENDENCIES} -eq 1 ] ; then

        #
        # Be sure Brew is already installed.
        # We are using our own repository instead of owncloud/owncloud,
        # because we want to manage that part ourselves.
        #
        brew tap kwillems/owncloud
        brew install $(brew deps mirall)

        brew install iniparser
        brew install qtkeychain

        #
        # If --force is passed, Homebrew will allow keg-only formulae to be linked.
        #
        brew link neon --force

        #
        # The following is not really needed.
        #
        #brew install cmocka argp-standalone

        #
        # Latex en Sphinx are only needed for documentation. Be sure MacPorts is
        # already installed if you are going to install them nevertheless.
        #
        #sudo port install texlive-latex
        #sudo port install py27-sphinx
        #sudo port select --set python python27
        #sudo port select --set sphinx py27-sphinx

        echo $'\nAll dependencies, libraries and other necessary thingies should be installed now.\n'

        if [ ${DEPENDENCIES_ONLY} -eq 1 ] ; then
            exit 0
        fi
    fi
}



#================================================================================
#
#        NAME: buildMirallAndPackage
# DESCRIPTION: Build and package.
#              If finished copy DMG to the folder 'client'.
#
#================================================================================

function buildMirallAndPackage() {
    mkdir install
    mkdir mirall-build
    cd mirall-build

    ownThemeDir=""
    if [ ${OWNTHEME} -eq 1 ] ; then
        ownThemeDir="-DOEM_THEME_DIR=${BUILD_DIR}/mirall/mytheme"
    fi

    updateParam=""
    if [ -n "${macUpdateURL}" ] ; then
        updateParam="-DAPPLICATION_UPDATE_URL=${macUpdateURL}"
    fi

    cmake -DCMAKE_PREFIX_PATH=/usr/local/opt/qt5/ \
        -DCMAKE_INSTALL_PREFIX=../install \
        -DCMAKE_BUILD_TYPE="Debug" ../mirall \
        ${ownThemeDir} ${updateParam}

    pause

    make install

    if [ ${CODESIGN} -eq 1 ] ; then
		cd "${BUILD_DIR}"/install
        if [ -n "${macDeveloperIDApplication}" ] ; then
            for file in *.app
            do
                source "${BUILD_DIR}"/mirall/admin/osx/sign_app.sh "${file}" "${macDeveloperIDApplication}"
            done
        else
            echo $'\nThere is no Developer ID Application entered in \"config\", so nothing is code signed.\n'
        fi

	    if [ -n "${macDeveloperIDInstaller}" ] ; then
		    source "${BUILD_DIR}"/mirall-build/admin/osx/create_mac.sh "${BUILD_DIR}"/install "${BUILD_DIR}"/mirall-build "${macDeveloperIDInstaller}"
		else
            echo $'\nThere is no Developer ID Installer entered in \"config\", so nothing is code signed.\n'
        fi
	else
		source "${BUILD_DIR}"/mirall-build/admin/osx/create_mac.sh "${BUILD_DIR}"/install "${BUILD_DIR}"/mirall-build
	fi

    cd "${BUILD_DIR}"
    cp "${BUILD_DIR}"/install/*.pkg "${CUR_DIR}"/client
    cp "${BUILD_DIR}"/install/*.pkg.tbz "${CUR_DIR}"/client
}



#================================================================================
#
#        NAME: signDMG
# DESCRIPTION: Code sign the PKG.
#              Runs when CODESIGN=1 and macDeveloperIDInstaller exists
#              and is longer than 0.
#              Only used with parameter -so (sign only).
#
#================================================================================

function signDMG() {
    if [ ${CODESIGN} -eq 1 ] ; then
        if [ -n "${macDeveloperIDInstaller}" ] ; then
        	cd "${CUR_DIR}"/client
            for file in *.pkg
            do
        	    productsign --sign "${macDeveloperIDInstaller}" "${file}" "signed_${file}"
    	    done
        else
        	echo $'\nThere is no Developer ID Installer entered in \"config\", so nothing is code signed.\n'
        fi
    fi
}



#================================================================================
#
#        NAME: checkSignDMGOnly
# DESCRIPTION: If CODESIGN_ONLY=1 the script will stop after code signing.
#
#================================================================================

function checkSignDMGOnly() {
    if [ ${CODESIGN_ONLY} -eq 1 ] ; then
        signDMG
        exit 0
    fi
}



#================================================================================
#
#        NAME: signSparkle
# DESCRIPTION: Create a DSA signature and store it in a TXT file.
#              Runs when SPARKLE is set and the path and name of the private key
#              is set in ${sparklePrivateKey} and this private key is present at
#              the given location.
#
#================================================================================

function signSparkle() {
    if [ ${SPARKLE} -eq 1 ] ; then
        if [ -n "${sparklePrivateKey}" ] ; then
            if [ -f "${sparklePrivateKey}" ] ; then
                cd "${CUR_DIR}"/client
                openssl=/usr/bin/openssl

                for file in *.tbz
                do
                    $openssl dgst -sha1 -binary < "${file}" | $openssl dgst -dss1 -sign "${sparklePrivateKey}" | $openssl enc -base64 > dsa-signature-for-\<\<"${file}"\>\>.txt
                done
                echo $'\nDSA signature written to TXT files(s)\n'
            else
                echo $'\nCould not find a Sparkle private key, so no DSA Signature is created.\n'
            fi
        else
            echo $'\nThere is no Sparkle private key entered in \"config\", so no DSA Signature is created.\n'
        fi
    fi
}



#================================================================================
#
#        NAME: checkSparkleOnly
# DESCRIPTION: If SPARKLE_ONLY=1 the script will stop after writing
#              a DSA signature to a TXT.
#
#================================================================================

function checkSparkleOnly() {
    if [ ${SPARKLE_ONLY} -eq 1 ] ; then
        signSparkle
        exit 0
    fi
}



#================================================================================
#
#        NAME: code section
# DESCRIPTION: Run run run ...
#
#================================================================================

checkHelp
checkSignDMGOnly
checkSparkleOnly
buildMacDependencies
makeBuildEnv
grabMirall
buildCustomizations
buildMirallAndPackage
signSparkle
cleanBuildGarbage
showMessage



#================================================================================
#
#        NAME: code section
# DESCRIPTION: Leave
#
#================================================================================

exit 0