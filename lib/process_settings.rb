# frozen_string_literal: true

require 'active_support'
require 'active_support/deprecation'

module ProcessSettings
end

require 'process_settings/monitor'

module ProcessSettings
  class << self
    # Setter method for assigning the monitor instance for ProcessSettings to use
    #
    # @example
    #
    # ProcessSettings.instance = ProcessSettings::FileMonitor.new(...)
    #
    # @param [ProcessSettings::AbstractMonitor] monitor The monitor to assign for use by ProcessSettings
    def instance=(monitor)
      if monitor && !monitor.is_a?(ProcessSettings::AbstractMonitor)
        raise ArgumentError, "Invalid monitor of type #{monitor.class.name} provided. Must be of type ProcessSettings::AbstractMonitor"
      end

      @instance = monitor
    end

    # Getter method for retrieving the current monitor instance being used by ProcessSettings
    #
    # @return [ProcessSettings::AbstractMonitor]
    def instance
      @instance ||= lazy_create_instance
    end

    # This is the main entry point for looking up settings in the process.
    #
    # @example
    #
    # ProcessSettings['path', 'to', 'setting']
    #
    # will return 42 in this example settings YAML:
    # +code+
    #   path:
    #     to:
    #       setting:
    #         42
    # +code+
    #
    # @param [Array(String)] path The path of one or more strings.
    #
    # @param [Hash] dynamic_context Optional dynamic context hash. It will be merged with the static context.
    #
    # @param [boolean] required If true (default) will raise `SettingsPathNotFound` if not found; otherwise returns `nil` if not found.
    #
    # @return setting value
    def [](*path, dynamic_context: {}, required: true)
      instance[*path, dynamic_context: dynamic_context, required: required]
    end

    private

    def lazy_create_instance
      ActiveSupport::Deprecation.warn("Lazy creation of FileMonitor instance is deprecated and will be removed in v1.0.0")
      Monitor.instance
    end
  end
end
