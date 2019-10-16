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

module ListenStub
  @watches = []
  @args = []

  class << self
    attr_accessor :args

    def to(*args, &block)
      @watches << [*args, block]
    end

    def start
    end

    def trigger_watchers
      while (watch = @watches.shift)
        watch.last.call(*args.shift)
      end
    end
  end
end
