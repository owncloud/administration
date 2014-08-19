Documentation
=============

General
-------
These set of files have the purpose to build the desktop clients for ownCloud. There are four files concerned.
The building itself is done by ``makemac.sh`` for the Mac client and ``makewinlin.sh`` voor de Windows and Linux clients.
Configuration can be done in ``config``, while some code used by both ``makemac.sh`` and ``makewinlin.sh`` is in ``library``.

``makemac.sh`` should run on OSX 10.9 or newer and ``makewinlin.sh`` on OpenSUSE 13.1 64 bit.
The scripts are supposed to run on fresh build systems. Using virtual machines would be pretty handy and convenient.

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
In ``config`` you can enter all information needed for code signing the Windows and the Mac clients. You will need to purchase the required certificates yourselve.


Sparkle
-------

If you want to use the Sparkle updater for the Mac client you have to install the Sparkle framework on your Mac before you build that client.
Download the package on http://sparkle-project.org/, unpack it and copy ``SPARKLE.framework`` and its contents to ``./Library/Frameworks/``.

Furthermore you have to generate a keypair. In the folder you just unpacked run ``./bin/generate_keys.sh``.
Copy the public key (``dsa_pub.pem``) to ``./replacements/mirall/admin/osx/sparkle/``.
Back up the private key (``dsa_priv.pem``) and keep it safe. You do not want anyone else getting it. If you lose it, you will not be able to issue any new updates.

In ``config`` you enter the path and name of your private key. If ``makemac.sh`` is run with the parameter ``-sp`` a DSA signature is created for each build DMG file. That signature has to be filled in the so called appcast you have to upload to your server. An example of such an appcast can be found in ``/buildenv/mirall/admin/osx/sparkle/example_update_rss.rss``.

