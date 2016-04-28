This is the server that is called from ownCloud to check if a new version of the server is available.

## How to release a new update

1. Adjust config/config.php for the update
2. Adjust tests/integration/features/update.feature for the integration tests

If the tests are not passing the TravisCI test execution will fail.

## Example calls

Deployed URL: http://updates.owncloud.com/server/
Example call: update-server/?version=8x2x0x12x1448709225.0768x1448709281xstablexx2015-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e
```xml
<?xml version="1.0"?>
<owncloud>
  <version>8.2.1.4</version>
  <versionstring>ownCloud 8.2.1</versionstring>
  <url>https://download.owncloud.org/community/owncloud-8.2.1.zip</url>
  <web>https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html</web>
</owncloud>
```
