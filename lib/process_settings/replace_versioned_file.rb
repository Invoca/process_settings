# frozen_string_literal: true

require_relative 'targeted_settings'

module ProcessSettings
  # This class will override a file with a higher version file; it accounts for minor version number use
  module ReplaceVersionedFile
    class << self
      def replace_file_on_newer_file_version(source_file_path, destination_file_path)
        source_file_path.to_s      == '' and raise ArgumentError, "source_file_path not present"
        destination_file_path.to_s == '' and raise ArgumentError, "destination_file_path not present"

        if source_version_is_newer?(source_file_path, destination_file_path)
          FileUtils.mv(source_file_path, destination_file_path)
        elsif source_file_path != destination_file_path # make sure we're not deleting destination file
          if File.exist?(source_file_path)
            FileUtils.remove_file(source_file_path) # clean up, remove left over file
          end
        end
      end

      private

      def source_version_is_newer?(source_file_path, destination_file_path)
        if File.exist?(source_file_path)
          if File.exist?(destination_file_path)
            source_version      = ProcessSettings::TargetedSettings.from_file(source_file_path, only_meta: true).version
            destination_version = ProcessSettings::TargetedSettings.from_file(destination_file_path, only_meta: true).version

            Gem::Version.new(source_version) > Gem::Version.new(destination_version)
          else
            true
          end
        end
      end
    end
  end
end
