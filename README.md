# ProcessSettings
This gem provides dynamic settings for Ruby processes. The settings are stored in YAML.
Settings are managed in a git repo, in separate YAML files for each concern (for example, each micro-service). Each YAML file can be targeted based on matching context values (for example, `service_name`).


The context can be either static to the process (for example, `service_name` or `datacenter`) or dynamic (for example, the current web request `domain`).

## Dependencies
* Ruby >= 2.6
* ActiveSupport >= 4.2, < 7

## Installation
To install this gem directly on your machine from rubygems, run the following:
```ruby
gem install process_settings
```

To install this gem in your bundler project, add the following to your Gemfile:
```ruby
gem 'process_settings', '~> 0.4'
```

## Usage
The `ProcessSettings::FileMonitor` and related classes can be freely created and used at any time.
But typical usage is through the `ProcessSettings.instance`.
That should be configured at process startup before use.
### Configuration
Before using `ProcessSettings.instance`, you must first configure the path to the combined process settings file on disk,
and provide a logger.
```ruby
require 'process_settings'

ProcessSettings.instance = ProcessSettings::FileMonitor.new("/etc/process_settings/combined_process_settings.yml",
                                                            logger: logger)
```
### Instance Initialization
The `ProcessSettings` is a hybrid singleton. The class attribute `instance` returns
the current instance as set at configuration time. Deprecated: If not already set, this is lazy-created based on the above configuration.

The monitor should be initialized with static (unchanging) context for your process:
```
ProcessSettings.instance.static_context = {
  "service_name" => "frontend",
  "datacenter" => "AWS-US-EAST-1"
}
```
The `static_context` is important because it is used to pre-filter settings for the process.
For example, a setting that is targeted to `service_name: frontend` will match the above static context and
be simplified to `true`. In other processes with a different `service_name`, such a targeted setting will be
simplified to `false` and removed from memory.

Note that the `static_context` as well as `dynamic_context` must use strings, not symbols, for both keys and values.

### Reading Settings
For the following section, consider this `combined_process_settings.yml` file:
```
---
- filename: frontend.yml
  settings:
    frontend:
      log_level: info
- filename: frontend-microsite.yml
  target:
    domain: microsite.example.com
  settings:
    frontend:
      log_level: debug
- meta:
    version: 27
    END: true
```

To read a setting, application code should call the `[]` method on the `ProcessSettings` class. For example:
```
log_level = ProcessSettings['frontend', 'log_level']
=> "info"
```
#### ProcessSettings[] interface
The `ProcessSettings[]` method delegates to `ProcessSettings.instance#[]` on the `instance`.

`[]` interface:

```
[](*path, dynamic_context: {}, required: true)
```

|argument|description|
|--------|-------------|
|_path_    |A series of 1 or more comma-separated strings forming a path to navigate the `settings` hash, starting at the top.|
|`dynamic_context:` |An optional hash of dynamic settings, used to target the settings. This will automatically be deep-merged with the static context. It may not contradict the static context. |
|`required:` |A boolean indicating if the setting is required to be present. If a setting is missing, then if `required` is truthy, a `ProcesssSettings::SettingsPathNotFound` exception will be raised. Otherwise, `nil` will be returned. Default: `true`.

Example with `dynamic_context`:
```
log_level = ProcessSettings['frontend', 'log_level',
                            dynamic_context: { "domain" => "microsite.example.com" }
                           ]
=> "debug"
```

Example with `required: true` (default) that was not found:
```
http_version = ProcessSettings['frontend', 'http_version']

exception raised!

ProcessSettings::SettingsPathNotFound: No settings found for path ["frontend", "http_version"]
```

Here is the same example with `required: false`, applying a default value of `2`:
```
http_version = ProcessSettings['frontend', 'http_version', required: false] || 2
```

### Dynamic Settings

The `ProcessSettings::FileMonitor` loads settings changes dynamically whenever the file changes,
by using the [listen](https://github.com/guard/listen) gem which in turn uses the `INotify` module of the Linux kernel, or `FSEvents` on MacOS. There is no need to restart the process or send it a signal to tell it to reload changes.

There are two ways to get access the latest settings from inside the process:

#### Read Latest Setting Through `ProcessSettings[]`

The simplest approach--as shown above--is to read the latest settings at any time through `ProcessSettings[]` (which delegates to `ProcessSettings.instance`):
```
http_version = ProcessSettings['frontend', 'http_version']
```

#### Register a `when_updated` Callback
Alternatively, if you need to execute initially and whenever the value is updated, register a callback with `ProcessSettings.instance#when_updated`:
```
ProcessSettings.instance.when_updated do
  logger.level = ProcessSettings['frontend', 'log_level']
end
```
By default, the `when_updated` block is called initially when registered. We've found this to be convenient in most cases; it can be disabled by passing `initial_update: false`, in which case the block will be called 0 or more times in the future, when any of the process settings for this process change.

`when_updated` is idempotent.

In case you need to cancel the callback later, `when_updated` returns a handle (the block itself) which can later be passed into `cancel_when_updated`.

Note that all callbacks run sequentially on the shared change monitoring thread, so please be considerate!

## Targeting
Each settings YAML file has an optional `target` key at the top level, next to `settings`.

If there is no `target` key, the target defaults to `true`, meaning all processes are targeted for these settings. (However, the settings may be overridden by other YAML files. See "Precedence" below.)

### Hash Key-Values Are AND'd
To `target` on context values, provide a hash of key-value pairs. All keys must match for the target to be met. For example, consider this target hash:
```
target:
  service_name: frontend
  datacenter: AWS-US-EAST-1
```
This will be applied in any process that has `service_name == "frontend"` AND is running in `datacenter == "AWS-US-EAST-1"`.

### Multiple Values Are OR'd
Values may be set to an array, in which case the key matches if _any_ of the values matches. For example, consider this target hash:
```
target:
  service_name: [frontend, auth]
  datacenter: AWS-US-EAST-1
```
This will be applied in any process that has (`service_name == "frontend"` OR `service_name == "auth"`) AND `datacenter == "AWS-US-EAST-1"`.

### Precedence
The settings YAML files are always combined in alphabetical order by file path. Later settings take precedence over the earlier ones.

### Testing
For testing, it is often necessary to set a specific override hash for the process_settings values to use in
that use case.  The `ProcessSettings::Testing::Helpers` module is provided for this purpose.  It can be used to
override a specific hash of process settings, while leaving the rest intact, and resetting back to the defaults
after the test case is over.  Here are some examples using various testing frameworks:

#### RSpec
##### `spec_helper.rb`
```ruby
require 'process_settings/testing/helpers'

RSpec.configure do |config|
  # ...

  include ProcessSettings::Testing::Helpers

  # Note: the include above will automatically register a global after block that will reset process_settings to their initial values.
  # ...
end
```

##### `process_settings_spec.rb`
```ruby
require 'spec_helper'

RSpec.describe SomeClass do
  before do
    stub_process_settings(honeypot: { answer_odds: 100 })
  end

  # ...
end
```

#### Test::Unit / Minitest
```ruby
require 'process_settings/testing/helpers'

context SomeClass do
  include ProcessSettings::Testing::Helpers

  # Note: the include above will automatically register a teardown block that will reset process_settings to their initial values.

  setup do
    stub_process_settings(honeypot: { answer_odds: 100 })
  end

  # ...
end
```

## Contributions

Contributions to this project are always welcome.  Please thoroughly read our [Contribution Guidelines](https://github.com/Invoca/process_settings/blob/master/CONTRIBUTING.md) before starting any work.
