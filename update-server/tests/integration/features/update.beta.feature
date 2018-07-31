Feature: Testing the update scenario of releases on the beta channel
##### Please always order by version number descending #####

  ##### Tests for 10.0.x should go below #####
  Scenario: Updating an outdated ownCloud 10.0.9 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "10.0.9"
    When The request is sent
    Then The response is empty

  Scenario: Updating an outdated ownCloud 10.0.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "10.0.0"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-10.0.9.zip"
    And URL to documentation is "https://doc.owncloud.org/server/10.0/admin_manual/maintenance/upgrade.html"

  ##### Tests for 9.1.x should go below #####
  Scenario: Updating an outdated ownCloud 9.1.8 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.1.8"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-10.0.9.zip"
    And URL to documentation is "https://doc.owncloud.org/server/10.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 9.1.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.1.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "9.1.8" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-9.1.8.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.1/admin_manual/maintenance/upgrade.html"

  ##### Tests for 9.0.x should go below #####
  Scenario: Updating an outdated ownCloud 9.0.11 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.0.11"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-9.1.8.zip"

  Scenario: Updating an outdated ownCloud 9.0.10 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.0.10"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-9.0.11.zip"

  Scenario: Updating an outdated ownCloud 9.0.5 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.0.5"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-9.0.11.zip"

  Scenario: Updating an outdated ownCloud 9.0.4 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.0.4"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-9.0.11.zip"

  Scenario: Updating an outdated ownCloud 9.0.3 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.0.3"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-9.0.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 9.0.2 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.0.2"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-9.0.4.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 9.0.1 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.0.1"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-9.0.4.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 9.0.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "9.0.0"
    When The request is sent
    Then The response is non-empty
    And URL to download is "https://download.owncloud.org/community/owncloud-9.0.4.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html"

  ##### Tests for 8.2.x should go below #####
  Scenario: Updating an outdated ownCloud 8.2.11 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.2.11"
    When The request is sent
    Then The response is non-empty
    And Update to version "9.0.11" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-9.0.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/9.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.2.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.2.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.2.11" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.2.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html"

  ##### Tests for 8.1.x should go below #####
  Scenario: Updating an outdated ownCloud 8.1.12 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.1.12"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.2.11" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.2.11.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.2/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.1.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.1.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.1.12" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.1.12.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html"

  ##### Tests for 8.0.x should go below #####
  Scenario: Updating an outdated ownCloud 8.0.16 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.0.16"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.1.12" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.1.12.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.1/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 8.0.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "8.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.0.16" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.0.16.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html"

  ##### Tests for 7.0.x should go below #####
  Scenario: Updating an outdated ownCloud 7.0.15 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "7.0.15"
    When The request is sent
    Then The response is non-empty
    And Update to version "8.0.16" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-8.0.16.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html"

  Scenario: Updating an outdated ownCloud 7.0.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "7.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "7.0.15" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-7.0.15.zip"
    And URL to documentation is "https://doc.owncloud.org/server/8.0/admin_manual/maintenance/upgrade.html"

  ##### Tests for 6.0.x should go below #####
  Scenario: Updating an outdated ownCloud 6.0.0 on the beta channel
    Given There is a release with channel "beta"
    And The received version is "6.0.0"
    When The request is sent
    Then The response is non-empty
    And Update to version "7.0.15" is available
    And URL to download is "https://download.owncloud.org/community/owncloud-7.0.15.zip"
    And URL to documentation is "https://doc.owncloud.org/server/7.0/admin_manual/maintenance/upgrade.html"

