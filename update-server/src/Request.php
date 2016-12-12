<?php
/**
 * ownCloud
 *
 * @author Lukas Reschke <lukas@owncloud.com>
 * @copyright Copyright (c) 2016, ownCloud GmbH.
 *
 * This code is covered by the ownCloud Commercial License.
 *
 * You should have received a copy of the ownCloud Commercial License
 * along with this program. If not, see <https://owncloud.com/licenses/owncloud-commercial/>.
 *
 */

namespace UpdateServer;

use UpdateServer\Exceptions\UnsupportedReleaseException;

class Request {
	/** @var int|null */
	private $majorVersion = null;
	/** @var int|null */
	private $minorVersion = null;
	/** @var int|null */
	private $maintenanceVersion = null;
	/** @var int|null */
	private $revisionVersion = null;
	/** @var float|null */
	private $installationMtime = null;
	/** @var int|null */
	private $lastCheck = null;
	/** @var null|string */
	private $channel = null;
	/** @var null|string */
	private $edition;
	/** @var null|string */
	private $build;
	/** @var null|string */
	private $remoteAddress;

	/**
	 * @param string $versionString
	 * @param array $server
	 * @throws UnsupportedReleaseException If the release is not supported by this update script.
	 */
	public function __construct($versionString,
								array $server) {
		$this->readVersion($versionString, $server);
	}

	/**
	 * @return int|null
	 */
	public function getMajorVersion() {
		return $this->majorVersion;
	}

	/**
	 * @return int|null
	 */
	public function getMinorVersion() {
		return $this->minorVersion;
	}

	/**
	 * @return int|null
	 */
	public function getMaintenanceVersion() {
		return $this->maintenanceVersion;
	}

	/**
	 * @return int|null
	 */
	public function getRevisionVersion() {
		return $this->revisionVersion;
	}

	/**
	 * @return float|null
	 */
	public function getInstallationMtime() {
		return $this->installationMtime;
	}

	/**
	 * @return int|null
	 */
	public function getLastCheck() {
		return $this->lastCheck;
	}

	/**
	 * @return null|string
	 */
	public function getChannel() {
		return $this->channel;
	}

	/**
	 * @return null|string
	 */
	public function getEdition() {
		return $this->edition;
	}

	/**
	 * @return null|string
	 */
	public function getBuild() {
		return $this->build;
	}

	/**
	 * @return null|string
	 */
	public function getRemoteAddress() {
		return $this->remoteAddress;
	}

	/**
	 * @param string $versionString
	 * @param array $server
	 * @throws UnsupportedReleaseException If the release is not supported by this update script.
	 */
	private function readVersion($versionString, array $server) {
		$version = explode('x', $versionString);

		if (count($version) === 9) {
			$this->majorVersion = (int)$version['0'];
			$this->minorVersion = (int)$version['1'];
			$this->maintenanceVersion = (int)$version['2'];
			$this->revisionVersion = (int)$version['3'];
			$this->installationMtime = (float)$version['4'];
			$this->lastCheck = (int)$version['5'];
			$this->channel = $version['6'];
			$this->edition = $version['7'];
			$this->build = explode(' ', substr(urldecode($version['8']), 0, strrpos(urldecode($version['8']), ' ')))[0];
			$this->remoteAddress = (isset($server['REMOTE_ADDR']) ? $server['REMOTE_ADDR'] : '');
		} else {
			throw new UnsupportedReleaseException;
		}
	}
}
