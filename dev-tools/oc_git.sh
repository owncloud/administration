#!/bin/bash
# sudo chmod +x oc_git.sh
# sudo ./oc_git.sh

# creates or updates a git clone for testing

gittargetdir='/var/www/oclg'
calldir=$(pwd)

# service apache2 stop
# service mysql stop

# syncing github files
# if gittargetdir folder has no contents do a git clone else a git pull
if [ "$(ls -A $gittargetdir)" ]; then
# folder not empty
 cd $gittargetdir
 git pull
 git shortlog -2
 cd $gittargetdir/apps2
 rm -r $gittargetdir/apps2/music
 rm -r $gittargetdir/apps2/gallery
 git clone https://github.com/owncloud/gallery.git
 git clone https://github.com/owncloud/music.git

else
# folder is empty
 mkdir -p $gittargetdir
 cd $gittargetdir
 echo 'git clone core: '$gittargetdir
 git clone https://github.com/owncloud/core.git ./
 echo 'git clone apps: '$gittargetdir/apps2
 git clone https://github.com/owncloud/apps.git $gittargetdir/apps2
 echo 'git clone 3rdparty: '$gittargetdir
 git clone https://github.com/owncloud/3rdparty.git $gittargetdir/3rdparty
 echo 'git clone gallery and music: '$gittargetdir/apps2
 cd $gittargetdir/apps2
 git clone https://github.com/owncloud/gallery.git
 git clone https://github.com/owncloud/music.git

 git shortlog -2

 # check if the directories exist. if not create one. this is due the
 # fact, that this dirs may miss in the github core master file.
 echo "Checking / creating if dir (data, config) exists"
 mkdir -p $gittargetdir/apps
 mkdir -p $gittargetdir/apps2
 mkdir -p $gittargetdir/data
 mkdir -p $gittargetdir/config

 echo
 echo "When you have finalized installing OC, run 'oc_git_post.sh'."
 echo
fi

# grants permissions independent on fresh install or update
echo "Granting permissions"
chown -R www-data:www-data $gittargetdir/apps
chown -R www-data:www-data $gittargetdir/apps2
chown -R www-data:www-data $gittargetdir/data
chown -R www-data:www-data $gittargetdir/config

cd $calldir

# service mysql start
# service apache2 start
