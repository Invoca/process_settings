# frozen_string_literal: true

require 'process_settings/monitor'
require 'process_settings/settings'
require 'process_settings/target_and_settings'

require 'process_settings/testing/monitor'

module ProcessSettings
  module Testing
    module Helpers

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
          *ProcessSettings::FileMonitor.default_instance.statically_targeted_settings,
          new_target_and_settings
        ]

        ProcessSettings::Monitor.instance = ProcessSettings::Testing::Monitor.new(
          new_process_settings,
          logger: ProcessSettings::FileMonitor.default_instance.logger
        )
      end
    end
  end
end
