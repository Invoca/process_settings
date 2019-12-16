# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "process_settings/version"

Gem::Specification.new do |spec|
  spec.name        = 'process_settings'
  spec.version     = ProcessSettings::VERSION
  spec.license     = 'MIT'
  spec.date        = '2019-09-19'
  spec.summary     = 'Dynamic process settings'
  spec.description = 'Targeted process settings that dynamically reload without restarting the process'
  spec.authors     = ['Invoca']
  spec.email       = 'development+ps@invoca.com'
  spec.files       = Dir.glob("{bin,lib}/**/*") + %w[README.md LICENSE]
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.homepage    = 'https://rubygems.org/gems/process_settings'
  spec.metadata    = { 'source_code_uri' => 'https://github.com/Invoca/process_settings' }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'listen', '~> 3.2.1'
end
