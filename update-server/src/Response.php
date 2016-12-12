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

class Response {
	/** @var Config */
	private $config;
	/** @var Request */
	private $request;

	/**
	 * @param Request $request
	 * @param Config $config
	 */
	public function __construct(Request $request,
								Config $config) {
		$this->request = $request;
		$this->config = $config;
	}

	/**
	 * @return array
	 */
	private function getFuzzySearches() {
		// The search scheme is defined as following:
		// 1. Major.Minor.Maintenance.Revision
		$searches[] = $this->request->getMajorVersion().'.'.$this->request->getMinorVersion().'.'.$this->request->getMaintenanceVersion().'.'.$this->request->getRevisionVersion();
		// 2. Major.Minor.Maintenance
		$searches[] = $this->request->getMajorVersion().'.'.$this->request->getMinorVersion().'.'.$this->request->getMaintenanceVersion();
		// 3. Major.Minor
		$searches[] = $this->request->getMajorVersion().'.'.$this->request->getMinorVersion();
		// 4. Major
		$searches[] = $this->request->getMajorVersion();
		// 5. Major . 0
		$searches[] = $this->request->getMajorVersion().'.0';
		return $searches;
	}

	/**
	 * Code for the stable editions
	 *
	 * @param array $versions
	 * @param string $completeCurrentVersion
	 * @return string
	 */
	private function getStableResponse(array $versions, $completeCurrentVersion) {
		$newVersion = '';
		foreach($this->getFuzzySearches() as $search) {
			if(isset($versions[$search])) {
				$newVersion = $versions[$search];
				if(version_compare($newVersion['latest'], $completeCurrentVersion, '<=')) {
					return '';
				} else {
					break;
				}
			}
		}

		if($newVersion === '') {
			return '';
		}

		$downloadUrl = 'https://download.owncloud.org/community/owncloud-'.$newVersion['latest'].'.zip';
		if(isset($newVersion['downloadUrl'])) {
			$downloadUrl = $newVersion['downloadUrl'];
		}

		$writer = new \XMLWriter();
		$writer->openMemory();
		$writer->startDocument('1.0','UTF-8');
		$writer->setIndent(4);
		$writer->startElement('owncloud');
		$writer->writeElement('version', $newVersion['latest']);
		$writer->writeElement('versionstring', 'ownCloud '.$newVersion['latest']);
		$writer->writeElement('url', $downloadUrl);
		$writer->writeElement('web', $newVersion['web']);
		$writer->endElement();
		$writer->endDocument();
		return $writer->flush();
	}

	/**
	 * Code for the daily builds
	 *
	 * @param array $versions
	 * @return string
	 */
	private function getDailyResponse(array $versions) {
		foreach($this->getFuzzySearches() as $search) {
			if(isset($versions[$search])) {
				if((time() - strtotime($this->request->getBuild())) > 172800) {
					$newVersion = $versions[$search];
					$writer = new \XMLWriter();
					$writer->openMemory();
					$writer->startDocument('1.0','UTF-8');
					$writer->setIndent(4);
					$writer->startElement('owncloud');
					$writer->writeElement('version', '100.0.0.0');
					$writer->writeElement('versionstring', 'ownCloud daily');
					$writer->writeElement('url', $newVersion['downloadUrl']);
					$writer->writeElement('web', $newVersion['web']);
					$writer->endElement();
					$writer->endDocument();
					return $writer->flush();
				}
			}
		}

		return '';
	}

	/**
	 * @return string
	 */
	public function buildResponse() {
		$completeCurrentVersion = $this->request->getMajorVersion().'.'.$this->request->getMinorVersion().'.'.$this->request->getMaintenanceVersion();

		switch ($this->request->getChannel()) {
			case 'production':
				return $this->getStableResponse($this->config->get('production'), $completeCurrentVersion);
			case 'stable':
				return $this->getStableResponse($this->config->get('stable'), $completeCurrentVersion);
			case 'beta':
				return $this->getStableResponse($this->config->get('beta'), $completeCurrentVersion);
			case 'daily':
				return $this->getDailyResponse($this->config->get('daily'));
			default:
				return '';
		}
	}
}
