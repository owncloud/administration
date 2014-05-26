#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2014 Thomas Müller deepdiver@owncloud.com
#
# Jenkins translation sync job script
#
if [ "$#" -ne 2 ]; then
    echo "Usage: job.sh <branch> <app>"
    exit 1
fi

set -x

BRANCH=$1
APPNAME=$2

git checkout $BRANCH
git branch
git pull --rebase

mkdir -p l10n/.tx
cd l10n
rm -rf l10n.pl
wget https://raw.githubusercontent.com/owncloud/administration/master/jenkins/translation_sync/l10n.pl
cd ..

if [[ ! -f l10n/.tx/config ]]; then
cat >l10n/.tx/config <<EOL
[main]
host = https://www.transifex.com
lang_map = ja_JP: ja

[owncloud.$APPNAME]
file_filter = <lang>/$APPNAME.po
source_file = templates/$APPNAME.pot
source_lang = en
type = PO
EOL

fi

#
# update translations
#
cd l10n/ 
perl l10n.pl $APPNAME read 
tx -d push -s 
tx -d pull -a 
perl l10n.pl $APPNAME write 
find . -name \*.po -type f -delete
find . -name \*.pot -type f -delete
cd ..

#
# push to git
#
git status
git add l10n
git commit -am "[tx-robot] updated from transifex"
git push origin $BRANCH
git status
echo "done"
