# ProcessSettings [![Build Status](https://travis-ci.org/Invoca/process_settings.svg?branch=master)](https://travis-ci.org/Invoca/process_settings) [![Coverage Status](https://coveralls.io/repos/github/Invoca/process_settings/badge.svg?branch=master)](https://coveralls.io/github/Invoca/process_settings?branch=master) [![Gem Version](https://badge.fury.io/rb/process_settings.svg)](https://badge.fury.io/rb/process_settings)
This gem adds the ability to your ruby logger, to accept conditional context, and utilize it when formatting your log entry.

## Installation
To install this gem directly on your machine from rubygems, run the following:
```ruby
gem install process_settings
```

To install this gem in your bundler project, add the following to your Gemfile:
```ruby
gem 'process_settings', '~> 0.1'
```

To use an unreleased version, add it to your Gemfile for Bundler:
```ruby
gem 'process_settings', git: 'git://github.com/Invoca/process_settings.git'
```

## Usage
### Initialization
To use the contextual logger, all you need to do is initailize the object with your existing logger
```ruby
require 'process_settings'
```

TODO: Fill in here how to use the Monitor's instance method to get current settings, how to register for on_change callbacks, etc.

## Contributions

Contributions to this project are always welcome.  Please thoroughly read our [Contribution Guidelines](https://github.com/Invoca/process_settings/blob/master/CONTRIBUTING.md) before starting any work.
