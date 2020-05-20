# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

require_relative '../monitor'
require_relative '../hash_with_hash_path'

module ProcessSettings
  module Testing
    # This class implements the Monitor#targeted_value interface but is stubbed to use a simple hash in tests
    class MonitorStub
      def initialize(settings_hash)
        ActiveSupport::Deprecation.warn("ProcessSettings::Testing::MonitorStub is deprecated and will be removed in future versions. Use ProcessSettings::Testing::Monitor instead.", caller)
        @settings_hash = HashWithHashPath[settings_hash]
      end

      def [](*path, dynamic_context: {}, required: true)
        targeted_value(*path, dynamic_context: dynamic_context, required: required)
      end

      def targeted_value(*path, dynamic_context:, required: true)
        result = @settings_hash.mine(*path, not_found_value: :not_found)

        if result == :not_found
          if required
            raise SettingsPathNotFound, "no settings found for path #{path.inspect}"
          else
            nil
          end
        else
          result
        end
      end
    end
  end
end
