# frozen_string_literal: true

module ProcessSettings
end

require 'process_settings/monitor'

module ProcessSettings
  class << self
    def [](*path, dynamic_context: {}, required: true)
      Monitor.instance.targeted_value(*path, dynamic_context: dynamic_context, required: required)
    end
  end
end
