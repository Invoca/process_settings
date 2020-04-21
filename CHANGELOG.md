# CHANGELOG for `process_settings`

Inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Note: this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.1] - 2020-04-21
### Fixed
- Fixed bug where `MonitorStub` was not responding to `#[]`

## [0.8.0] - 2020-04-07
### Added
- `Monitor` instance now implements `#[]` and `ProcessSettings[]` delegates to it.
  This enables the preferred usage of `when_updated`, where the `settings` block argument is used to read the settings:
  ```ruby
  ProcessSettings::Monitor.instance.when_updated do |settings|
    logger.level = settings['gem', 'listen', 'log_level']
  end
  ````

## [0.7.1] - 2020-03-31
### Fixed
- Reverted `rescue` syntax that required Ruby 2.6 since that broke some gems still on Ruby 2.4.

## [0.7.0] - 2020-03-31
### Added
- `ProcessSettings::Monitor.when_updated` was added as a replacement to `ProcessSettings::Monitor.on_change`.  This allows the user
  to not only register a block to execute when a change is detected, but also allows the initial execution of the block during setup.
  This allows for cleaner, dryer code.

### Modified
- Don't check for file_path or logger config if `instance =` has already been called;
  it's not necessary.

### Deprecated
- `ProcessSettings::Monitor.on_change` has been deprecated; it will be removed in version `1.0.0`.
  `ProcessSettings::Monitor.when_updated` should be used instead.

[0.8.0]: https://github.com/Invoca/process_settings/compare/v0.7.1...v0.8.0
[0.7.1]: https://github.com/Invoca/process_settings/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/Invoca/process_settings/compare/v0.6.0...v0.7.0
