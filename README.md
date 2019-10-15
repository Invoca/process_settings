# ProcessSettings [![Build Status](https://travis-ci.org/Invoca/process_settings.svg?branch=master)](https://travis-ci.org/Invoca/process_settings) [![Coverage Status](https://coveralls.io/repos/github/Invoca/process_settings/badge.svg?branch=master)](https://coveralls.io/github/Invoca/process_settings?branch=master) [![Gem Version](https://badge.fury.io/rb/process_settings.svg)](https://badge.fury.io/rb/process_settings)
This gem provides dynamic settings for Linux processes. These settings are stored in JSON.
They including a targeting notation so that each settings group can be targeted based on matching context values.
The context can be either static to the process (for example, service_name or data_center) or dynamic (for example, the domain of the current web request).

## Installation
To install this gem directly on your machine from rubygems, run the following:
```ruby
gem install process_settings
```

To install this gem in your bundler project, add the following to your Gemfile:
```ruby
gem 'process_settings', '~> 0.3'
```

To use an unreleased version, add it to your Gemfile for Bundler:
```ruby
gem 'process_settings', git: 'git@github.com:Invoca/process_settings'
```

## Usage
### Initialization
To use the contextual logger, all you need to do is initailize the object with your existing logger
```ruby
require 'process_settings'
```

TODO: Fill in here how to use the Monitor's instance method to get current settings, how to register for on_change callbacks, etc.

### Dynamic Settings

In order to load changes dynamically, `ProcessSettings` relies on INotify module of the Linux kernel. On kernels that do not have this module (MacOS for example), you will see a warning on STDERR that changes will not be loaded while the process runs.


## Contributions

Contributions to this project are always welcome.  Please thoroughly read our [Contribution Guidelines](https://github.com/Invoca/process_settings/blob/master/CONTRIBUTING.md) before starting any work.
