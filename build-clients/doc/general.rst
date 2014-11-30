Documentation
=============

General
-------
These set of files have the purpose to build the desktop clients for ownCloud. There are four files concerned.
The building itself is done by ``makemac.sh`` for the Mac client and ``makewinlin.sh`` voor de Windows and Linux clients.
Configuration can be done in ``config``, while some code used by both ``makemac.sh`` and ``makewinlin.sh`` is in ``library``.

``makemac.sh`` should run on OSX 10.9, Mavericks that is.
IT PRODUCES AN CLIENT WITH AN ERROR WHEN BUILD ON YOSEMITE. This will be fixed in futere releases of Mirall.
``makewinlin.sh`` should run on OpenSUSE 13.2 64 bit.
The scripts are supposed to run on fresh build systems. Using virtual machines would be pretty handy and convenient.

After the build proces has finished you can find the client(s) in a folder called ``client``.

Warning
-------
The scripts have no significant error checking. So, basicly you are on your own.
By the way, they are bash scripts.

Options
-------
With ``makemac.sh -h`` or ``makewinlin.sh -h`` you will get a concise manpage with all the available options. ``makemac.sh`` and ``makewinlin.sh`` have each different options.

The first time you run ``makemac.sh`` or ``makewinlin.sh`` you have to provide the parameter ``-d`` or ``-do``, so all needed dependencies will be installed.
More options at a time can be used.

Theming
-------
All information needed for theming the client can be found in the comments for ``buildCustomizations()`` in ``library``. Read them carefully or stay out there!

Code signing
------------
In ``config`` you can enter all information needed for code signing the Windows and the OS X clients. You will need to purchase the required certificates yourselve.

Xcode
-----
When you build the OS X  client XCode and the command line tools should be installed on the Mac on which you build the client.

Homebrew
--------
To build the OS X client extra dependencies are required on the building machine. These dependencies can be installed with Homebrew: http://brew.sh/ The script will take care of this, but Homebrew should be installed on your building Mac.

Packages
--------
Contrary to earlier versions, version 1.7 and later of the client for OS X is packaged as a PKG installer. Therefore the Packages tool from http://s.sudre.free.fr/Software/Packages/about.html should be available on the (virtual) machine on which you build the client for OS X.
So, download Packages and install it.

Sparkle
-------
When the Sparkle updater is implemented the OS X client itself will notify a user if there is a new version of the client. Unfortunatly Sparkle can not handle PKG files at the moment. In order to serve Sparkle the client will be packet and should be uploaded to your server as a TBZ file. For human downloads you provide the PKG file to your visitors.

If you want to use the Sparkle updater for the OS X client you have to install the Sparkle framework on your building Mac.
Download the package on http://sparkle-project.org, unpack it and copy ``SPARKLE.framework`` and its contents to ``./Library/Frameworks/``.

Furthermore you have to generate a keypair. In the folder you just unpacked run ``./bin/generate_keys.sh``.
Copy the public key (``dsa_pub.pem``) to ``./replacements/mirall/admin/osx/sparkle/``.
Back up the private key (``dsa_priv.pem``) and keep it safe. You do not want anyone else getting it. If you lose it, you will not be able to issue any new updates.

In ``config`` you enter the path and name of your private key. If ``makemac.sh`` runs with the parameter ``-sp`` a DSA signature is created for each build TBZ file. That signature has to be filled in in the so called appcast you have to upload to your server. An example of such an appcast can be found in ``/buildenv/mirall/admin/osx/sparkle/example_update_rss.rss``.