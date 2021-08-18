# Changelog
All notable changes to this project will be documented in this file.

**ATTN**: This project uses [semantic versioning](http://semver.org/).

## [Unreleased]
### Fixed
- Fixed "taken IsoGenerator" line in *_map.txt log file.

### Added
- Added profession and skill points to player log in stats section.
- Added coordinates to player log.
- Added health level and infected information to player log.
- Added traits to player log.

## [v0.3.0] - 2019-12-01
### Added
- Added Events.OnEnterVehicle callback. Saves coordinates of the player's entry into the vehicle to {{dd-mm-yy_h-i}}_cmd.txt log file.
- Added Events.OnExitVehicle callback. Saves player's exit coordinates from vehicle to {{dd-mm-yy_h-i}}_cmd.txt log file.
- Added Events.EveryHours callback. Makes saving the character to {{dd-mm-yy_h-i}}_player.txt log file every one ingame hour.

### Changed
- Events can be turned on or off in the configuration of the LogExtender object.

### Fixed
- Removed levelup entries from the character’s creation window until the server is fully connected.

## [v0.2.0] - 2019-09-24
### Added
- Added level to dump player stats.
- Start writing changelog.

### Changed
- Code refactoring. Create a LogExtender object and define its methods.

### Fixed
- Fix inconsistent levelup event from administrator panel #1.

## [v0.1.2] - 2019-08-26
### Added
- Add readme.

## [v0.1.1] - 2019-08-25
### Added
- Add "taken IsoGenerator" line to *_map.txt log file.

## [v0.1.0] - 2019-08-25
### Added
- Add basic implementation.

[Unreleased]: https://github.com/game-servers/pz-mod-log-extender/compare/v0.3.0...HEAD
[v0.3.0]: https://github.com/game-servers/pz-mod-log-extender/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/game-servers/pz-mod-log-extender/compare/v0.1.2...v0.2.0
[v0.1.2]: https://github.com/game-servers/pz-mod-log-extender/compare/v0.1.1...v0.1.2
[v0.1.1]: https://github.com/game-servers/pz-mod-log-extender/compare/v0.1.0...v0.1.1
