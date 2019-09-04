# frozen_string_literal: true

require 'process_settings/process_settings_monitor'
require 'pry'

module ProcessSettings::StreamLogger
  class << self
    def new(logger)
      logger.extend(self)
    end
  end

  def stream(source_stream, context = {})
    if (value = stream_enabled?(source_stream, context))
      message = yield value
      info(message)
    end
  end

  private

  def stream_enabled?(source_stream, context)
    statically_targeted_settings = ProcessSettings::ProcessSettingsMonitor.instance.current_statically_targeted_settings
    statically_targeted_settings.reduce(nil) do |result, target_and_settings|
      # find last value from matching targets
      if target_and_settings.target.target_key_matches?(context)
        if (streams = target_and_settings.process_settings['logging' => 'streams'])
          unless (value = ProcessSettings::HashPath.hash_at_path(streams, source_stream)).nil?
            result = value
          end
        end
      end
      result
    end
  end
end
