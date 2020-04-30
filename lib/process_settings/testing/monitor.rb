# frozen_string_literal: true

require 'active_support/core_ext'
require 'process_settings/abstract_monitor'

module ProcessSettings
  module Testing

    # A special instance of the monitor specifically used for testing that
    # allows the providing of a settings array from memory to initialize
    # the ProcessSetting Monitor for testing
    #
    # @param Array settings_array
    # @param Logger logger
    class Monitor < ::ProcessSettings::AbstractMonitor
      def initialize(settings_array, logger:)
        super(logger: logger)
        @statically_targeted_settings = settings_array
      end

      private

      def load_statically_targetted_settings(force_retarget: false)
        @statically_targeted_settings
      end
    end
  end
end
