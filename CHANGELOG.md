# CHANGELOG for `process_settings`

Inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Note: this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.15.1] - 2020-09-23
### Fixed
- Fixed bug where if `make` output of combined_process_settings.yml was unchanged (ignoring version number),
  that version would be considered a no-op and discarded
  EVEN IF it was different from what is live in S3.
  Now, the make output is compared to current as well as what's live in S3; if either are different,
  the new version is committed and pushed live.

## [0.15.0] - 2020-09-08
### Added
- Added a `warn` when dynamic keys overlap with static ones and added `full_context_cache` to avoid repetitive deep merges.

## [0.14.0] - 2020-08-13
### Changed
- Separated `ProcessSettings::Testing::Minitest::Helpers` from `ProcessSettings::Testing::RSpec::Helpers` since it is difficult
to infer which is which. Left `ProcessSettings::Testing::Helpers` as an alias for `ProcessSettings::Testing::RSpec::Helpers` for
backward-compatibility.

## [0.13.3] - 2020-08-11
### Fixed
- Fixed `Testing::Helpers` for `minitest` to define a `teardown` method rather than call a `teardown` helper.

## [0.13.2] - 2020-08-07
### Fixed
- Fixed typo in error message: "brew upgrade".

## [0.13.1] - 2020-08-06
### Changed
- Removed explicit `: null` because `libyaml` 0.2.5 doesn't write the trailing space to key off.
Instead, explicitly depend on the `psych` gem and check that libyaml is at least 0.2.5.

##  0.13.0 - 2020-08-06
### Not Used

## [0.12.0] - 2020-08-06
### Changed
- `bin/combine_process_settings` now uses an explicit `: null` value for null (nil in Ruby) values, vs.
the former implicit `: ` at end of line. This is important because the trailing space was sometimes deleted
when committed and pushed, depending on editor settings and git(hub) hook configuration. 

## [0.11.0] - 2020-06-16
### Added
- `ProcessSettings::Testing::Helpers` now automatically registers an `after`/`teardown` block to
  set `ProcessSettings.instance` back to the default that was there before it was optionally
  overridden by `stub_process_settings`.
- `ProcessSettings::FileMonitor.initialize` now accepts an optional keyword argument `environment:`.
  This is an environment string like can be found in `Rails.env` for Rails applications.
  It is used to infer to disable the listen thread in the 'test' environment.
  If left to its default of `nil`, the environment is inferred by the first of these values that is present:
  1. `Rails.env` (if available)
  2. `ENV['RAILS_ENV']`
  3. `ENV['SERVICE_ENV']`
- `ProcessSettings::FileMonitor#listen_thread_running?` indicates whether the listen thread
  is running.

### Changed
- Moved deprecation from `#initialize` up to `.new` so that warning will point to caller.
- Deprecated public `FileMonitor#start` method. This will become `private` in v1.0.
- Deprecated lazy `ProcessSettings#instance` explicitly so that warning will point to caller.
- Cleaned up noisy spec output including deprecation warnings.
- Explicit contract enforcement: `raise ArgumentError` if logger: passed as `nil`.
- Allow 'true' ('1') or 'false' ('0') values for `ENV['DISABLE_LISTEN_CHANGE_MONITORING']`;
  default to 'false' when `Rails.env || ENV['SERVICE_ENV']) == 'test'`.

### Fixed
- Fixed memoization of `Target.true_target`.

## [0.10.5] - 2020-05-27
### Fixed
- Fixed bug where setting a monitor instance at the `ProcessSettings` and the `ProcessSettings::Monitor`
can cause unexpected errors due to two monitors being configured.

## [0.10.4] - 2020-05-21
### Fixed
- Added missing `require 'active_support/deprecation'` in case caller hasn't done that.

## [0.10.3] - 2020-05-20
### Fixed
- Added missing `require 'active_support'` in case caller hasn't done that.

## [0.10.2] - 2020-05-18
### Fixed
- Fixed bug where running `bin/diff_process_settings` multiple times would cause errors by
switching the script to use `Tempdir` for generating temporary file name

## [0.10.1] - 2020-05-16
### Fixed
- Added missing `require_relative 'abstract_monitor'`.

## [0.10.0] - 2020-05-16
### Added
- `bin/diff_process_settings` now supports a `--silent` option (like `cmp --silent`) while still
  ignoring the meta-data in the file including the version number.

### Changed
- `bin/combine_process_settings` now uses the above when deciding whether to overwrite `combined_process_settings.yml`
   or leave it. Therefore if no settings change--just the version number--the output file will be left untouched.

## [0.9.0] - 2020-05-15
### Added
- Added a new `ProcessSettings::Testing::Monitor` class for testing with process settings
- Added a new `ProcessSettings::Testing::Helpers` module for testing with process settings
- Added support for rails 5 and 6.
- Added appraisal tests for all supported rails version: 4/5/6

### Changed
- Renamed `ProcessSettings::Monitor` to `ProcessSettings:FileMonitor`, with `Monitor` left as a (deprecated) alias.

### Deprecated
- Deprecated the `ProcessSettings::Testing::MonitorStub` to be replaced by the new `ProcessSettings::Testing::Monitor`
- `ProcessSettings::Monitor` will be replaced by `ProcessSettings::FileMonitor`

## [0.8.2] - 2020-04-22
### Fixed
- Fixed bug where an `ArgumentError` would raise out of `Target#with_static_context` when a target hash uses a nested key that doesn't exist in the static context

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

[0.15.1]: https://github.com/Invoca/process_settings/compare/v0.15.0...v0.15.1
[0.15.0]: https://github.com/Invoca/process_settings/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/Invoca/process_settings/compare/v0.13.3...v0.14.0
[0.13.3]: https://github.com/Invoca/process_settings/compare/v0.13.2...v0.13.3
[0.13.2]: https://github.com/Invoca/process_settings/compare/v0.13.1...v0.13.2
[0.13.1]: https://github.com/Invoca/process_settings/compare/v0.12.0...v0.13.1
[0.12.0]: https://github.com/Invoca/process_settings/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/Invoca/process_settings/compare/v0.10.5...v0.11.0
[0.10.5]: https://github.com/Invoca/process_settings/compare/v0.10.4...v0.10.5
[0.10.4]: https://github.com/Invoca/process_settings/compare/v0.10.3...v0.10.4
[0.10.3]: https://github.com/Invoca/process_settings/compare/v0.10.2...v0.10.3
[0.10.2]: https://github.com/Invoca/process_settings/compare/v0.10.1...v0.10.2
[0.10.1]: https://github.com/Invoca/process_settings/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/Invoca/process_settings/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/Invoca/process_settings/compare/v0.8.2...v0.9.0
[0.8.2]: https://github.com/Invoca/process_settings/compare/v0.8.1...v0.8.2
[0.8.1]: https://github.com/Invoca/process_settings/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/Invoca/process_settings/compare/v0.7.1...v0.8.0
[0.7.1]: https://github.com/Invoca/process_settings/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/Invoca/process_settings/compare/v0.6.0...v0.7.0
