# frozen_string_literal: true

require 'process_settings/monitor'
require 'process_settings/settings'
require 'process_settings/target_and_settings'

require 'process_settings/testing/monitor'

module ProcessSettings
  module Testing
    module Helpers
      class << self
        def included(including_klass)
          if including_klass.respond_to?(:after)  # rspec
            including_klass.after do
              ProcessSettings.instance = initial_instance
            end
          else                                    # minitest
            including_klass.define_method(:teardown) do
              ProcessSettings.instance = initial_instance
            end
          end
        end
      end
      # Adds the given settings_hash as an override at the end of the process_settings array, with default targeting (true).
      # Therefore this will override these settings while leaving others alone.
      #
      # @param [Hash] settings_hash
      #
      # @return none
      def stub_process_settings(settings_hash)
        new_target_and_settings = ProcessSettings::TargetAndSettings.new(
          '<test_override>',
          Target::true_target,
          ProcessSettings::Settings.new(settings_hash.deep_stringify_keys)
        )

        new_process_settings = [
          *initial_instance.statically_targeted_settings,
          new_target_and_settings
        ]

        ProcessSettings.instance = ProcessSettings::Testing::Monitor.new(
          new_process_settings,
          logger: initial_instance.logger
        )
      end

      def initial_instance
        @initial_instance ||= ProcessSettings.instance
      end
    end
  end
end
