# CHANGELOG for `process_settings`

Inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Note: this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] (Unreleased)

### Added

- `ProcessSettings::Monitor.when_updated` was added as a replacement to `ProcessSettings::Monitor.on_change`.  This allows the user
  to not only register a block to execute when a change is detected, but also allows the initial execution of the block during setup.
  This allows for cleaner, dryer code.

### Modified

- Don't check for file_path or logger config if `instance =` has already been called;
  it's not necessary.

### Deprecated

- `ProcessSettings::Monitor.on_change` has been deprecated. `ProcessSettings::Monitor.when_updated` should be used instead.
  This will be removed in version `1.0.0`

[0.6.1]: https://github.com/Invoca/process_settings/compare/v0.6.0...v0.6.1
