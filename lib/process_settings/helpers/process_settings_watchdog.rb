# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

module ProcessSettings
  class Watchdog
    class ProcessSettingsOutOfSync < StandardError; end

    MAX_MTIME_DIFFERENCE = 2.minutes

    def initialize(process_settings_file_path)
      @process_settings_file_path = process_settings_file_path or raise ArgumentError, "process_settings_file_path must be passed"
    end

    def check
      if version_from_memory != version_from_disk && (Time.now - mtime_from_disk) > MAX_MTIME_DIFFERENCE
        raise ProcessSettingsOutOfSync.new("ProcessSettings versions are out of sync!\n Version from Disk: #{version_from_disk}\n Version from Memory: #{version_from_memory}\n mtime of file: #{mtime_from_disk}")
      end
    end

    private

    attr_reader :process_settings_file_path

    def version_from_memory
      ProcessSettings.instance.untargeted_settings.version
    end

    def version_from_disk
      ProcessSettings::TargetedSettings.from_file(process_settings_file_path, only_meta: true).version
    end

    def mtime_from_disk
      File.mtime(process_settings_file_path)
    end
  end
end
