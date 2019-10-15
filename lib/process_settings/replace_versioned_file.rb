# frozen_string_literal: true

require_relative 'targeted_settings'

module ProcessSettings
  # This class will override a file with a higher version file; it accounts for minor version number use
  class ReplaceVersionedFile

    def replace_file_on_newer_file_version(source_file_name, destination_file_name)
      if source_version_is_newer?(source_file_name, destination_file_name)
        FileUtils.mv(source_file_name, destination_file_name)
      end
    end

    private

    def source_version_is_newer?(source_file_name, destination_file_name)
      source_version      = ProcessSettings::TargetedSettings.from_file(source_file_name, only_meta: true).version
      destination_version = ProcessSettings::TargetedSettings.from_file(destination_file_name, only_meta: true).version

      Gem::Version.new(source_version) > Gem::Version.new(destination_version)
    end
  end
end
