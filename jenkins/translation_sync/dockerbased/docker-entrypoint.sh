#!/usr/bin/env bash

if [[ ! -f /home/jenkins/.transifexrc ]]; then
	echo '/home/jenkins/.transifexrc is missing - you need to mount this in'
	exit
fi

if [ "$#" -ne 1 ]; then
    echo "The name of the app has to be passed in"
    exit
fi

cd /workspace/

# verbose and exit on error
set -xe

APPNAME=$1

mkdir -p l10n/.tx
cp /home/jenkins/l10n.pl l10n/

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
# running pre-proc step
#
if [[ -f l10n/preproc.sh ]]; then
	bash l10n/preproc.sh
fi

#
# update translations
#
cd l10n/
perl l10n.pl $APPNAME read
tx -d push -s
tx -d pull -a --minimum-perc=75
perl l10n.pl $APPNAME write
find . -name \*.po -type f -delete
find . -name \*.pot -type f -delete
cd ..

#
# cleanup
#
rm -rf l10n/l10n.pl
git rm -rf l10n/l10n.pl || true
git rm -rf l10n/uz.* || true
git rm -rf l10n/yo.* || true
git rm -rf l10n/ne.* || true
git rm -rf l10n/or_IN.* || true


#
# push to git
#
git status
git add l10n
git commit -am "[tx-robot] updated from transifex" || true
echo "done"

