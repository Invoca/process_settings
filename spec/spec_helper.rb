# frozen_string_literal: true

require 'rspec_junit_formatter'
require 'process_settings'

require 'pry'
require 'coveralls'
Coveralls.wear!

RSpec.configure do |config|
  config.add_formatter  :progress
  config.add_formatter  RspecJunitFormatter, ENV['JUNIT_OUTPUT'] || 'spec/reports/rspec.xml'

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups

  RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 2_000
end
