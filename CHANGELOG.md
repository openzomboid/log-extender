# Changelog
All notable changes to this project will be documented in this file.

**ATTN**: This project uses [semantic versioning](http://semver.org/).

## [Unreleased]

### Added
- Added serverside config to Sandbox options.

## [v0.6.0] - 2022-01-20
### Fixed
- Fixed display of safehouse membership in player log.

### Added
- Added vehicle enter and exit events contained vehicle id, type and center coordinate to `_player.txt` log file.
- Added vehicle attach and detach events to `_player.txt` log file.
- Added ovens and microwaves toggle event to `_cmd.txt` log file.
- Added campfire added and taken events to `_map.txt` log file.
- Added campfire light and extinguish events to `_cmd.txt` log file.

### Changed
- Vehicle enter and exit events marked as deprecated in `_cmd.txt` log file. This events will be removed in future releases.

## [v0.5.0] - 2021-12-14
### Fixed
- Fix for 41 mp build - remove skill points if PZ major version is 41.

## [v0.4.1] - 2021-09-14
### Fixed
- Profession is no longer written in the localization language. Used profession type instead of name.

## [v0.4.0] - 2021-08-20
### Fixed
- Fixed "taken IsoGenerator" line in *_map.txt log file.

### Added
- Added coordinates to player log.
- Added profession and skill points to player log in stats section.
- Added health level and infected information to player log.
- Added traits to player log.

## [v0.3.0] - 2019-12-01
### Added
- Added Events.OnEnterVehicle callback. Save coordinates of the player's entry into the vehicle to {{dd-mm-yy_h-i}}_cmd.txt log file.
- Added Events.OnExitVehicle callback. Saves player's exit coordinates from vehicle to {{dd-mm-yy_h-i}}_cmd.txt log file.
- Added Events.EveryHours callback. Makes saving the character to {{dd-mm-yy_h-i}}_player.txt log file every one ingame hour.

### Changed
- Events can be turned on or off in the configuration of the LogExtender object.

### Fixed
- Removed levelup entries from the character's creation window until the server fully connected.

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

[Unreleased]: https://github.com/openzomboid/log-extender/compare/v0.6.0...HEAD
[v0.6.0]: https://github.com/openzomboid/log-extender/compare/v0.5.0...v0.6.0
[v0.5.0]: https://github.com/openzomboid/log-extender/compare/v0.4.1...v0.5.0
[v0.4.1]: https://github.com/openzomboid/log-extender/compare/v0.4.0...v0.4.1
[v0.4.0]: https://github.com/openzomboid/log-extender/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/openzomboid/log-extender/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/openzomboid/log-extender/compare/v0.1.2...v0.2.0
[v0.1.2]: https://github.com/openzomboid/log-extender/compare/v0.1.1...v0.1.2
[v0.1.1]: https://github.com/openzomboid/log-extender/compare/v0.1.0...v0.1.1
