# ProcessSettings
This gem provides dynamic settings for Ruby processes. The settings are stored in YAML.
Settings are managed in a git repo, in separate YAML files for each concern (for example, each micro-service). Each YAML file can be targeted based on matching context values (for example, `service_name`).


The context can be either static to the process (for example, `service_name` or `datacenter`) or dynamic (for example, the current web request `domain`).

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
The `ProcessSettings::Monitor` and related classes can be freely created and used at any time.
But typical usage is through the `ProcessSettings::Monitor.instance`.
That should be configured at process startup before use.
### Configuration
Before using `ProcessSettings::Monitor.instance`, you must first configure the path to the combined process settings file on disk,
and provide a logger.
```ruby
require 'process_settings'

ProcessSettings::Monitor.file_path = "/etc/process_settings/combined_process_settings.yml"
ProcessSettings::Monitor.logger = logger
```
### Monitor Initialization
The `ProcessSettings::Monitor` is a hybrid singleton. The class attribute `instance` returns
the current instance. If not already set, this is lazy-created based on the above configuration.

The monitor should be initialized with static (unchanging) context for your process:
```
ProcessSettings::Monitor.static_context = {
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
The `ProcessSettings[]` method delegates to `ProcessSettings::Monitor#[]` on the `instance`.

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

The `ProcessSettings::Monitor` loads settings changes dynamically whenever the file changes,
by using the [listen](https://github.com/guard/listen) gem which in turn uses the `INotify` module of the Linux kernel, or `FSEvents` on MacOS. There is no need to restart the process or send it a signal to tell it to reload changes.

There are two ways to get access the latest settings from inside the process:

#### Read Latest Setting Through `ProcessSettings[]`

The simplest approach--as shown above--is to read the latest settings at any time through `ProcessSettings[]` (which delegates to `ProcessSettings::Monitor.instance`):
```
http_version = ProcessSettings['frontend', 'http_version']
```

#### Register an `on_change` Callback
Alternatively, if you need to execute some code when there is a change, register a callback with `ProcessSettings::Monitor#on_change`:
```
ProcessSettings::Monitor.instance.on_change do
  logger.level = ProcessSettings['frontend', 'log_level']
end
```
Note that all callbacks run sequentially on the shared change monitoring thread, so please be considerate!

There is no provision for unregistering callbacks. Instead, replace the `instance` of the monitor with a new one.

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
For testing, it is often necessary to set a specific hash for the process_settings values to use in that test case.
The `ProcessSettings::Testing::MonitorStub` class is provided for this purpose. It can be initialized with a hash and assigned to `ProcessSettings::Monitor.instance`. After the test runs, make sure to call `clear_instance`.
Note that it has no `targeting` or `settings` keys; it is stubbing the resulting settings hash _after_ targeting has been applied.
Here is an example using `rspec` conventions:
```
before do
  settings = { "honeypot" => { "answer_odds" => 100 } }
  ProcessSettings::Monitor.instance = ProcessSettings::Testing::MonitorStub.new(settings)
end

after do
  ProcessSettings::Monitor.clear_instance
end
```

## Contributions

Contributions to this project are always welcome.  Please thoroughly read our [Contribution Guidelines](https://github.com/Invoca/process_settings/blob/master/CONTRIBUTING.md) before starting any work.
