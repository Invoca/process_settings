# frozen_string_literal: true

require_relative 'targeted_settings'

module ProcessSettings
  # This class will override a file with a higher version file; it accounts for minor version number use
  class CopyVersionedFile

    def copy_file(source_file_name, destination_file_name)
      if copy_file?(source_file_name, destination_file_name)
        FileUtils.cp(source_file_name, destination_file_name)
      end
    ensure
      if source_file_name != destination_file_name # avoid removing source file if destination file is the same
        FileUtils.remove_file(destination_file_name)
      end
    end

    private

    def copy_file?(source_file_name, destination_file_name)
      source_version      = ProcessSettings::TargetedSettings.from_file(source_file_name, only_meta: true).version
      destination_version = ProcessSettings::TargetedSettings.from_file(destination_file_name, only_meta: true).version

      Gem::Version.new(source_version) > Gem::Version.new(destination_version)
    end
  end
end
