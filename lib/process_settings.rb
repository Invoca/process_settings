# frozen_string_literal: true

module ProcessSettings
end

require 'process_settings/monitor'

module ProcessSettings
  class << self
    def [](value, dynamic_context)
      Monitor.instance.targeted_value(value, dynamic_context)
    end
  end
end
