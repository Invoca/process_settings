# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = 'process_settings'
  spec.version     = '0.0.1'
  spec.license     = 'MIT'
  spec.date        = '2019-09-04'
  spec.summary     = 'Dynamic process settings'
  spec.description = 'Targed process settings that dynamically reload without restarting the process'
  spec.authors     = ['Colin Kelley']
  spec.email       = 'colin@invoca.com'
  spec.files       = Dir.glob("{bin,lib}/**/*") + %w[README.rdoc LICENCE]
  spec.executables = Dir.glob("bin/*").map { |f| f.sub("\A bin\/x", "") }
  spec.homepage    = 'https://rubygems.org/gems/process_settings'
  spec.metadata    = { 'source_code_uri' => 'https://github.com/Invoca/process_settings' }

  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'monotonic_tick_count'
end
