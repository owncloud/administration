#!/bin/bash
# sudo chmod +x oc_git_delete.sh
# sudo ./oc_git_delete.sh

# deletes a owncloud-git installation, but without the database cleanup
# and without deleting the remaining gittargetdir directory

gittargetdir='/var/www/oclg'

# deleting github files
# check presence of gittdagetdir
if [ "$(ls -A $gittargetdir)" ]; then
 # folder not empty
 echo "Deleting owncloud git development + .git/.htaccess files"
 rm -r $gittargetdir/*
 rm -r $gittargetdir/.g*
 rm -r $gittargetdir/.h*
 rm -r $gittargetdir/.i*
 rm -r $gittargetdir/.j*
 rm -r $gittargetdir/.s*
else
 # folder is empty
 echo "Nothing to delete"
fi

echo "Before you reinstall OC-git, delete the database and the db-users!"
