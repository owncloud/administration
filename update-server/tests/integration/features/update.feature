Feature: Testing the update scenario of releases

  ##### MODIFY THE FOLLOWING LINES BELOW WHEN AN UPDATE HAS BEEN PUBLISHED #####
  Scenario: Updating an outdated ownCloud 8.0.0 on the production channel
    Given There is a release with channel "production"
    And The received version is "8.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.0.11" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.0.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.1.0 on the production channel
    Given There is a release with channel "production"
    And The received version is "8.1.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.1.6" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.1.6.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.2.0 on the production channel
    Given There is a release with channel "production"
    And The received version is "8.2.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.2.3" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.2.3.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.0.0 on the stable channel
    Given There is a release with channel "stable"
    And The received version is "8.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.0.11" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.0.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.1.0 on the stable channel
    Given There is a release with channel "stable"
    And The received version is "8.1.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.1.6" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.1.6.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.2.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.2.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.2.3" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.2.3.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.0.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.0.11" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.0.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.1.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.1.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.1.6" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.1.6.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.2.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.2.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.2.3" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.2.3.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html"
  ##### MODIFY THE LINES ABOVE WHEN AN UPDATE HAS BEEN PUBLISHED #####

  Scenario: Updating an outdated ownCloud 6.0.0 on the production channel
    Given There is a release with channel "production"
    And The received version is "6.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "7.0.13" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-7.0.13.zip"
    And URL to documentation is "https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 6.0.0 on the stable channel
    Given There is a release with channel "stable"
    And The received version is "6.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "7.0.13" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-7.0.13.zip"
    And URL to documentation is "https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 6.0.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "6.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "7.0.13" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-7.0.13.zip"
    And URL to documentation is "https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an up-to-date ownCloud 8.2.100
    Given There is a release with channel "stable"
    And The received version is "8.2.100"
    When The request is sent
    Then The response is empty

  Scenario: Updating an outdated-dated ownCloud 6 daily
    Given There is a release with channel "daily"
    And The received version is "6.0.100"
    And the received build is "2015-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-7.0.13.zip"
    And URL to documentation is "https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated-dated ownCloud 6 daily
    Given There is a release with channel "daily"
    And The received version is "6.0.100"
    And the received build is "2012-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-7.0.13.zip"
    And URL to documentation is "https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an up-to-date ownCloud 6 daily
    Given There is a release with channel "daily"
    And The received version is "6.0.100"
    And the received build is "2019-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is empty

  Scenario: Updating an outdated-dated ownCloud 7 daily
    Given There is a release with channel "daily"
    And The received version is "7.0.100"
    And the received build is "2015-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.0.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated-dated ownCloud 7 daily
    Given There is a release with channel "daily"
    And The received version is "7.0.100"
    And the received build is "2012-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.0.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an up-to-date ownCloud 7 daily
    Given There is a release with channel "daily"
    And The received version is "7.0.100"
    And the received build is "2019-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is empty

  Scenario: Updating an outdated-dated ownCloud 8 daily
    Given There is a release with channel "daily"
    And The received version is "8.0.100"
    And the received build is "2015-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.1.6.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated-dated ownCloud 8 daily
    Given There is a release with channel "daily"
    And The received version is "8.0.100"
    And the received build is "2012-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.1.6.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an up-to-date ownCloud 8 daily
    Given There is a release with channel "daily"
    And The received version is "8.0.100"
    And the received build is "2019-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is empty

  Scenario: Updating an outdated-dated ownCloud 8.1 daily
    Given There is a release with channel "daily"
    And The received version is "8.1.100"
    And the received build is "2015-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.2.3.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated-dated ownCloud 8.1 daily
    Given There is a release with channel "daily"
    And The received version is "8.1.100"
    And the received build is "2012-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.2.3.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an up-to-date ownCloud 8.1 daily
    Given There is a release with channel "daily"
    And The received version is "8.1.100"
    And the received build is "2019-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is empty

  Scenario: Updating an outdated-dated ownCloud 8.2 daily
    Given There is a release with channel "daily"
    And The received version is "8.2.100"
    And the received build is "2015-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-daily-stable9.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated-dated ownCloud 8.2 daily
    Given There is a release with channel "daily"
    And The received version is "8.2.100"
    And the received build is "2012-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-daily-stable9.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an up-to-date ownCloud 8.2 daily
    Given There is a release with channel "daily"
    And The received version is "8.2.100"
    And the received build is "2019-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is empty

  Scenario: Updating an outdated-dated ownCloud 9.0 daily
    Given There is a release with channel "daily"
    And The received version is "9.0.100"
    And the received build is "2015-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-daily-master.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated-dated ownCloud 9.0 daily
    Given There is a release with channel "daily"
    And The received version is "9.0.100"
    And the received build is "2012-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-daily-master.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an up-to-date ownCloud 9.0 daily
    Given There is a release with channel "daily"
    And The received version is "9.0.100"
    And the received build is "2019-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is empty

  Scenario: Updating an outdated-dated ownCloud 9.1 daily
    Given There is a release with channel "daily"
    And The received version is "9.1.100"
    And the received build is "2015-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-daily-master.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.1/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated-dated ownCloud 9.1 daily
    Given There is a release with channel "daily"
    And The received version is "9.1.100"
    And the received build is "2012-10-19T18:44:30+00:00%208ee2009de36e01a9866404f07722892f84c16e3e"
    When The request is sent
    Then The response is non-empty
    And Update to version "100.0.0.0" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-daily-master.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.1/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an up-to-date ownCloud 9.1 daily
    Given There is a release with channel "daily"
    And The received version is "9.1.100"
    And the received build is "2019-10-19T18:44:30+00:00"
    When The request is sent
    Then The response is empty