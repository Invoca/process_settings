# frozen_string_literal: true

module ProcessSettings
end

require 'process_settings/monitor'

module ProcessSettings
  class << self
    def [](value, dynamic_context: {}, required: true)
      Monitor.instance.targeted_value(value, dynamic_context: dynamic_context, required: required)
    end
  end
end
