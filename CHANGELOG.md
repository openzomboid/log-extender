# Changelog
All notable changes to this project will be documented in this file.

**ATTN**: This project uses [semantic versioning](http://semver.org/).

## [Unreleased]
### Added
- Added skipping player tick log when character is dead.
- Added death log to player file.

## [v0.12.0] - 2024-06-03
### Fixed
- Fixed empty objName value in map_alternative log record. When player picked up IsoThumpable, placed and destroyed it LogExtender added line with empty objName value.
- Fixed bug when vehicle detach log contained same vehicle twice.
- Fixed error after destroy IsoRadio and IsoTelevision from Brush Tool with Sledgehammer.

### Added
- Added brush tool logs to `brushtool.txt` file.
- Added vehicle admin and cheat logs to `admin.txt` file.
- Added safehouse admin and cheat logs to `admin.txt` file.

### Changed
- Marked as deprecated fuctions `writeLog`, `getLogLinePrefix`, `getLocation`, `getPlayerSafehouses`, `getPlayerPerks`, `getPlayerTraits`, `getPlayerStats`, `getPlayerHealth`, `getVehicleInfo` on LogExtenderClient. This functions copied to logutils and will be REMOVED on next update! Modders, please use this functions from new location `logutils`.
- Changed function `logutils.getPlayerSafehouses` behavior - field `Owner` now is an array.
- Changed behavior of `player.txt` log file writing - field `Owner` now is an array.
- Moved client logs to separated files loggers.

## [v0.11.1] - 2022-12-22
### Fixed
- Fixed IsoTelevision ISDestroyStuffAction action.

### Added
- Added pickup action to map_alternative.txt log file.

## [v0.11.0] - 2022-12-13
### Fixed
- Fixed PVP hit logs. Sometimes mod writes hit user logs when player is already dead.

### Added
- Added traps pick upping logs to map log file.
- Added alternative destroying logs with sledge.
- Added alternative disassemble logs with tools.
- Added crafting logs.
- Added logs for add item action from ISCraftingUI panel in debug mode.

## [v0.10.0] - 2022-07-08
### Added
- Added player hit record to pvp log file.
- Added change safehouse owner action to safehouse log file.
- Added logs for send safehouse invite action.

## [v0.9.0] - 2022-06-09
### Added
- Added logs for admin add item actions from ISItemsListTable panel.
- Added logs for admin remove item and get item actions from ISPlayerStatsManageInvUI panel.
- Added logs for admin teleports.

### Removed
- Removed v41.65 supporting.

## [v0.8.0] - 2022-02-26
### Fixed
- Fixed logger for 41.66 build.

## [v0.7.1] - 2022-02-24
### Fixed
- Fixed safehouse detection on actions `take safehouse` and `release safehouse` by `/releasesafehouse` chat command.

## [v0.7.0] - 2022-02-23
### Fixed
- Fixed vehicles JSON-format output.

### Added
- Added serverside config to Sandbox options.
- Added safehouse events.

### Changed
- Field `hours` is rounded to two decimal places in stats section of `_player.txt` log file.
- Field `health` is rounded to the nearest integer in health section of `_player.txt` log file.

### Removed
- Removed fields `level` and `skill_points` from `_player.txt` log file. Not actual for b41.
- Removed deprecated Vehicle enter and exit events in `_cmd.txt` log file.

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
### Fixed
- Removed levelup entries from the character's creation window until the server fully connected.

### Added
- Added Events.OnEnterVehicle callback. Save coordinates of the player's entry into the vehicle to {{dd-mm-yy_h-i}}_cmd.txt log file.
- Added Events.OnExitVehicle callback. Saves player's exit coordinates from vehicle to {{dd-mm-yy_h-i}}_cmd.txt log file.
- Added Events.EveryHours callback. Makes saving the character to {{dd-mm-yy_h-i}}_player.txt log file every one ingame hour.

### Changed
- Events can be turned on or off in the configuration of the LogExtender object.

## [v0.2.0] - 2019-09-24
### Fixed
- Fix inconsistent levelup event from administrator panel #1.

### Added
- Added level to dump player stats.
- Start writing changelog.

### Changed
- Code refactoring. Create a LogExtender object and define its methods.

## [v0.1.2] - 2019-08-26
### Added
- Add readme.

## [v0.1.1] - 2019-08-25
### Added
- Add "taken IsoGenerator" line to *_map.txt log file.

## [v0.1.0] - 2019-08-25
### Added
- Add basic implementation.

[Unreleased]: https://github.com/openzomboid/log-extender/compare/v0.12.0...HEAD
[v0.12.0]: https://github.com/openzomboid/log-extender/compare/v0.11.1...v0.12.0
[v0.11.1]: https://github.com/openzomboid/log-extender/compare/v0.11.0...v0.11.1
[v0.11.0]: https://github.com/openzomboid/log-extender/compare/v0.10.0...v0.11.0
[v0.10.0]: https://github.com/openzomboid/log-extender/compare/v0.9.0...v0.10.0
[v0.9.0]: https://github.com/openzomboid/log-extender/compare/v0.8.0...v0.9.0
[v0.8.0]: https://github.com/openzomboid/log-extender/compare/v0.7.1...v0.8.0
[v0.7.1]: https://github.com/openzomboid/log-extender/compare/v0.7.0...v0.7.1
[v0.7.0]: https://github.com/openzomboid/log-extender/compare/v0.6.0...v0.7.0
[v0.6.0]: https://github.com/openzomboid/log-extender/compare/v0.5.0...v0.6.0
[v0.5.0]: https://github.com/openzomboid/log-extender/compare/v0.4.1...v0.5.0
[v0.4.1]: https://github.com/openzomboid/log-extender/compare/v0.4.0...v0.4.1
[v0.4.0]: https://github.com/openzomboid/log-extender/compare/v0.3.0...v0.4.0
[v0.3.0]: https://github.com/openzomboid/log-extender/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/openzomboid/log-extender/compare/v0.1.2...v0.2.0
[v0.1.2]: https://github.com/openzomboid/log-extender/compare/v0.1.1...v0.1.2
[v0.1.1]: https://github.com/openzomboid/log-extender/compare/v0.1.0...v0.1.1
