#!/bin/bash
# sudo chmod +x oc_git_delete.sh
# sudo sh ./oc_git_delete.sh

gittargetdir=/mnt/www/owncloud_git

# syncing github files
# if gittargetdir folder has no contents do a git clone else a git pull
if [ "$(ls -A $gittargetdir)" ]; then
 # folder not empty
 echo "Deleting owncloud git development + .git/.htaccess files"
 rm -r $gittargetdir/*
 rm -r $gittargetdir/.g*
 rm -r $gittargetdir/.h*
else
 # folder is empty
 echo "Nothing to delete"
fi

echo "Before you reinstall OC-git, delete the database and the db-users!"
 
