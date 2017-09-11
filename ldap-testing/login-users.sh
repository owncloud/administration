#!/bin/bash

server='localhost'
root_url='octest'
start_uid=0
end_uid=20

function loginUserViaPropfind {
    # New endpoint
    curl -b XDEBUG_SESSION=MROW4A -X PROPFIND -u $1:$1 -H "Depth: 1" --data-binary "<?xml version=\"1.0\"?>
    <d:propfind  xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\">
      <d:prop>
        <d:getlastmodified />
        <d:getetag />
        <d:getcontenttype />
        <d:resourcetype />
        <oc:fileid />
        <oc:permissions />
        <oc:size />
        <d:getcontentlength />
        <oc:tags />
        <oc:favorite />
        <oc:comments-unread />
        <oc:owner-display-name />
        <oc:share-types />
      </d:prop>
    </d:propfind>" "http://$server/$root_url/remote.php/dav/files/$1"
}

# Log in first zombie king (which is member of all the groups
loginUserViaPropfind 'zombieKing'
for i in $(seq $start_uid $end_uid); do
    # Log zombies in range
    user="zombie$i"
    loginUserViaPropfind $user
done

