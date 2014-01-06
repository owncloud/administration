#!/bin/bash
# sudo chmod +x oc_git.sh
# sudo sh ./oc_git.sh

gittargetdir=/mnt/www/owncloud_git
calldir=$(pwd)

# service apache2 stop
# service mysql stop


# syncing github files
# if gittargetdir folder has no contents do a git clone else a git pull
if [ "$(ls -A $gittargetdir)" ]; then
# folder not empty
 cd $gittargetdir
 git pull
 git log -2
 cd $calldir

else
# folder is empty
 cd $gittargetdir
 echo 'git clone core: '$gittargetdir
 git clone https://github.com/owncloud/core.git ./
 echo -e '\ngit clone apps: '$gittargetdir/apps2
 git clone https://github.com/owncloud/apps.git $gittargetdir/apps2
 echo -e '\ngit clone 3rdparty: '$gittargetdir
 git clone https://github.com/owncloud/3rdparty.git 
 git log -2
 cd $calldir

 # check if the directories exist. if not create one. this is due the
 # fact, that this dirs may miss in the github core master file.
 echo "Checking / creating if dir (data, config) exists"
 mkdir -p $gittargetdir/data
 mkdir -p $gittargetdir/config

 echo "Granting permissions"
 chown -R www-data:www-data $gittargetdir/apps
 chown -R www-data:www-data $gittargetdir/apps2
 chown -R www-data:www-data $gittargetdir/data
 chown -R www-data:www-data $gittargetdir/config

 echo
 echo "When you have finalized installing OC, run 'oc_git_post.sh'."
 echo
fi

# service mysql start
# service apache2 start

