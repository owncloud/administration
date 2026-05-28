# Administration

<!-- OSPO-managed README | Generated: 2026-04-16 | v2 -->

[![License](https://img.shields.io/badge/License-See%20Repository-blue.svg)](LICENSE) [![ownCloud OSPO](https://img.shields.io/badge/OSPO-ownCloud-blue)](https://kiteworks.com/opensource) [![Docker Hub](https://img.shields.io/docker/pulls/owncloud)](https://hub.docker.com/r/owncloud/server)

This repository contains a collection of administration, build, and DevOps tools for ownCloud. It includes scripts and configurations for Jenkins CI integration, OpenBuildService packaging, Docker setups, LDAP testing utilities, client build scripts, performance testing tools, update server tooling, release signing, and other operational utilities used in the ownCloud development and release workflow.

> **Note:** This repository is in maintenance/legacy mode and is no longer actively developed.

## Part of Classic (OC10)

This repository provided supporting infrastructure for [ownCloud Server (Classic)](https://github.com/owncloud/core) and the broader ownCloud ecosystem. Its tools were used for building, testing, packaging, and deploying ownCloud components.

This component is included in the [ownCloud Server Docker image](https://hub.docker.com/r/owncloud/server).

> **Note:** This repository is currently in Archived/Legacy mode. It is no longer actively maintained and exists primarily for historical reference. The tools and scripts it contains may be outdated.

## Getting Started

Browse the subdirectories for specific tools:

- `docker/` - Docker-related configurations
- `jenkins/` - Jenkins CI integration scripts
- `build-clients/` - Client build scripts
- `performance-tests/` - Performance testing tools
- `signing/` - Release signing utilities
- `ldap-testing/` - LDAP testing helpers
- `update-server/` - Update server tooling
- `package_tests/` - Package testing scripts

## Documentation

- [ownCloud Server documentation](https://doc.owncloud.com)

## Community & Support

**[Star](https://github.com/owncloud/administration)** this repo and **Watch** for release notifications!

- [ownCloud Website](https://owncloud.com)
- [Community Discussions](https://github.com/orgs/owncloud/discussions)
- [Matrix Chat](https://app.element.io/#/room/#owncloud:matrix.org)
- [Documentation](https://doc.owncloud.com)
- [Enterprise Support](https://owncloud.com/contact-us/)
- [OSPO Home](https://kiteworks.com/opensource)

## Contributing

We welcome contributions! Please read the [Contributing Guidelines](CONTRIBUTING.md)
and our [Code of Conduct](CODE_OF_CONDUCT.md) before getting started.

### Workflow

- **Rebase Early, Rebase Often!** We use a rebase workflow. Always rebase on the target branch before submitting a PR.
- **Dependabot**: Automated dependency updates are managed via Dependabot. Review and merge dependency PRs promptly.
- **Signed Commits**: All commits **must** be PGP/GPG signed. See [GitHub's signing guide](https://docs.github.com/en/authentication/managing-commit-signature-verification).
- **DCO Sign-off**: Every commit must carry a `Signed-off-by` line:
  ```
  git commit -s -S -m "your commit message"
  ```
- **GitHub Actions Policy**: Workflows may only use actions that are (a) owned by `owncloud`, (b) created by GitHub (`actions/*`), or (c) verified in the GitHub Marketplace.

## Security

**Do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities at **<https://security.owncloud.com>** -- see [SECURITY.md](SECURITY.md).

Bug bounty: [YesWeHack ownCloud Program](https://yeswehack.com/programs/owncloud-bug-bounty-program)

## License

See [LICENSE](LICENSE) for license details.

## About the ownCloud OSPO

The [Kiteworks Open Source Program Office](https://kiteworks.com/opensource), operating under
the [ownCloud](https://owncloud.com) brand, launched on May 5, 2026, to steward the open source
ecosystem around ownCloud's products. The OSPO ensures transparent governance, license compliance,
community health, and sustainable collaboration between the open source community and
[Kiteworks](https://www.kiteworks.com), which acquired ownCloud in 2023.

- **OSPO Home**: <https://kiteworks.com/opensource>
- **GitHub**: <https://github.com/owncloud>
- **ownCloud**: <https://owncloud.com>

For questions about the OSPO or licensing, contact ospo@kiteworks.com.

### License Migration to Apache 2.0

The OSPO is driving a strategic relicensing of ownCloud repositories toward the
[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0), following
the [Apache Software Foundation's third-party license policy](https://www.apache.org/legal/resolved.html).

Individual repositories will migrate as their audit is completed. The LICENSE file
in each repo reflects its **current** license status (not the target).

**Current license: Not detected.** The OSPO will determine the current license status of this
repository before planning any migration steps. If you know the intended license, please open an
issue or contact ospo@kiteworks.com.
