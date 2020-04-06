# frozen_string_literal: true

module ProcessSettings
end

require 'process_settings/monitor'

module ProcessSettings
  class << self
    # []
    #
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
      Monitor.instance[*path, dynamic_context: dynamic_context, required: required]
    end
  end
end
