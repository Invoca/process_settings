# frozen_string_literal: true

require 'process_settings'

require 'pry'
require 'coveralls'
Coveralls.wear!

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end

module INotify
  class Notifier
    def initialize
      @watches = []
    end

    def watch(*args, &block)
      @watches << [*args, block]
    end

    def trigger_watchers
      while (watch = @watches.shift)
        watch.last.call
      end
    end
  end
end
