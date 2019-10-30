# ProcessSettings
This gem provides dynamic settings for Linux processes. The settings are stored in JSON.
Settings are managed in a git repo, in separate YAML files for each concern (for example, each micro-service). Each YAML file can be targeted based on matching context values (for example, `service_name`).


The context can be either static to the process (for example, service_name or data_center) or dynamic (for example, the current web request `domain`).

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
`ProcessSettings` must be configured before use.
### Configuration
To use `process_settings`, you must first configure the path to the combined process settings file on disk,
and provide a logger.
```ruby
require 'process_settings'

ProcessSettings::Monitor.file_path = "/etc/process_settings/combined_process_settings.yml"
ProcessSettings::Monitor.logger = logger
```
### Monitor Initialization
The `ProcessSettings::Monitor` is a modified singleton. There is a class method `instance` that returns
the current instance. If not already set, this is lazy-created based on the above configuration.

The monitor should be initialized with static (unchanging) context for your process:
```
ProcessSettings::Monitor.static_context = {
  "service_name" => "frontend",
  "data_center" => "AWS-US-EAST-1"
}
```
The `static_context` is important because it is used to pre-filter settings for the process.
For example, a setting that is targeted to `service_name: frontend` will match the above static context and
be simplified to `true`. In other processes with a different `service_name`, such a targeted setting will be
simplified to `false` and removed from memory.

Note that the `static_context` must use strings, not symbols, for its keys and values.

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

[](*path, dyanmic_context: {}, required: true)
```

|argument|description|
|--------|-------------|
|_path_    |A series of 1 or more comma-separated strings forming a path to navigate the `settings` hash, starting at the top.|
|`dynamic_context:` |An optional hash of dynamic settings, used to target the settings. This will automatically be merged with the static context. It may not contradict the static context. |
|`required:` |A boolean indicating if the setting is required to be present. If a setting is missing, then if `required` is truthy, a `ProcesssSettings::SettingsPathNotFound` exception will be raised. Otherwise, `nil` will be returned. Default: `true`.

Example with `dynamic_context`:
```
dynamic_context = {
  "domain" => "microsite.example.com"
}
log_level = ProcessSettings['frontend', 'log_level', dynamic_context: dynamic_context]
=> "debug"
```

Example with `required: true` (default) that was not found:
```
http2_version = ProcessSettings['frontend', 'http_version']

exception raised!

ProcessSettings::SettingsPathNotFound: No settings found for path ["frontend", "http_version"]
```

Same example with `required: false` that applies a default value of `2` if not found:
```
http_version = ProcessSettings['frontend', 'http_version', required: false] || 2
```

### Dynamic Settings

In order to detect changes dynamically, `ProcessSettings::Monitor` relies on the `listen` gem using INotify module of the Linux kernel, or `FSEvents` on MacOS.

## Targeting
Each settings YAML file has an optional `target` key at the top level, next to `settings`.

If there is no `target` key, the target defaults to `true` meaning all processes are targeted for these settings. (However, the settings may be overridden by other YAML files. See "Precedence" below.)

### Hash Key-Values Are AND'd
To `target` on context values, provide a hash of key-value pairs. All keys must be truthy for the target to be met. For example, consider this target hash:
```
target:
  service_name: frontend
  data_center: AWS-US-EAST-1
```
This will be applied in any process that has `service_name` == "frontend" AND is running in `data_center` == "AWS-US-EAST-1".

### Multiple Values Are OR'd
Values may be set to an array. In this case, that key matches if any of the values matches. For example, consider this target hash:
```
target:
  service_name: [frontend, auth]
  data_center: AWS-US-EAST-1
```
This will be applied in any process that has (`service_name` == "frontend" OR `service_name` == "auth") AND `data_center` == "AWS-US-EAST-1".

### Precedence
The settings YAML files are always combined in alphabetical order by file path. Later settings take precedence over the earlier ones.

## Contributions

Contributions to this project are always welcome.  Please thoroughly read our [Contribution Guidelines](https://github.com/Invoca/process_settings/blob/master/CONTRIBUTING.md) before starting any work.
