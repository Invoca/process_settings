# frozen_string_literal: true

require_relative 'targeted_settings'

module ProcessSettings
  # This class will override a file with a higher version file; it accounts for minor version number use
  module ReplaceVersionedFile
    class << self
      def replace_file_on_newer_file_version(source_file_name, destination_file_name)
        if source_version_is_newer?(source_file_name, destination_file_name)
          FileUtils.mv(source_file_name, destination_file_name)
        elsif source_file_name != destination_file_name # make sure we're not deleting destination file
          if File.exist?(source_file_name)
            FileUtils.remove_file(source_file_name) # clean up, remove left over file
          end
        end
      end

      private

      def source_version_is_newer?(source_file_name, destination_file_name)
        source_file_exists      = File.exist?(source_file_name)
        destination_file_exists = File.exist?(destination_file_name)

        if source_file_exists && destination_file_exists
          source_version      = ProcessSettings::TargetedSettings.from_file(source_file_name, only_meta: true).version
          destination_version = ProcessSettings::TargetedSettings.from_file(destination_file_name, only_meta: true).version

          Gem::Version.new(source_version) > Gem::Version.new(destination_version)
        elsif source_file_exists
          true
        else
          false
        end
      end
    end
  end
end
