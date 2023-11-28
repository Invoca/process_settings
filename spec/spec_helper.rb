# frozen_string_literal: true

require 'rspec_junit_formatter'
require 'process_settings'
require 'active_support/core_ext/object/blank'

require 'pry'

if ENV['GITHUB_ACTIONS'].presence
  require 'simplecov'
  require 'simplecov-lcov'

  SimpleCov.start do
    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter

    add_filter %w[version.rb initializer.rb]
  end
end

RSpec.configure do |config|
  config.add_formatter  :progress
  config.add_formatter  RspecJunitFormatter, ENV['JUNIT_OUTPUT'].presence || 'spec/reports/rspec.xml'

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups

  RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 2_000
end
