# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.1.0] - 2026-11-08

### Added

- `nat_gateway_id` creates an `azurerm_subnet_nat_gateway_association` between
  the subnet and an existing NAT gateway, for explicit outbound access. Defaults
  to `null`, which creates no association.
- Output `nat_gateway_association_id`.

## [2.0.0] - 2026-11-03

See the [GitHub release](https://github.com/moveeeax/terraform-azurerm-subnet/releases/tag/v2.0.0).

## [1.0.1] - 2026-11-03

See the [GitHub release](https://github.com/moveeeax/terraform-azurerm-subnet/releases/tag/v1.0.1).

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-subnet/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/moveeeax/terraform-azurerm-subnet/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/moveeeax/terraform-azurerm-subnet/compare/v1.0.1...v2.0.0
[1.0.1]: https://github.com/moveeeax/terraform-azurerm-subnet/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-subnet/tree/v1.0.0
