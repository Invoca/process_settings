# frozen_string_literal: true

require_relative 'targeted_settings'

module ProcessSettings
  # This class will override a file with a higher version file; it accounts for minor version number use
  module ReplaceVersionedFile
    class SourceVersionOlderError < StandardError; end
    class FileDoesNotExistError < StandardError; end

    class << self
      # Contracts
      #   source_file_path must be present
      #   destination_file_path must be present
      #   source_file_path must exist on filesystem
      #   source file version has to greater than or equal to destination version
      def replace_file_on_newer_file_version(source_file_path, destination_file_path)
        validate_arguments_are_passed_in(source_file_path, destination_file_path)
        validate_source_file_exists_on_system(source_file_path)
        validate_source_version_is_not_older(source_file_path, destination_file_path)

        if source_version_is_newer?(source_file_path, destination_file_path)
          FileUtils.mv(source_file_path, destination_file_path)
        elsif source_file_path != destination_file_path # make sure we're not deleting destination file
          FileUtils.rm_f(source_file_path) # clean up, remove left over file
        end
      end

      private

      def source_version_is_newer?(source_file_path, destination_file_path)
        if File.exist?(destination_file_path)
          source_version      = ProcessSettings::TargetedSettings.from_file(source_file_path, only_meta: true).version
          destination_version = ProcessSettings::TargetedSettings.from_file(destination_file_path, only_meta: true).version

          Gem::Version.new(source_version) > Gem::Version.new(destination_version)
        else
          true
        end
      end

      def validate_source_file_exists_on_system(source_file_path)
        File.exist?(source_file_path) or raise FileDoesNotExistError, "source file '#{source_file_path}' does not exist"
      end

      def validate_arguments_are_passed_in(source_file_path, destination_file_path)
        source_file_path.to_s      == '' and raise ArgumentError, "source_file_path not present"
        destination_file_path.to_s == '' and raise ArgumentError, "destination_file_path not present"
      end

      def validate_source_version_is_not_older(source_file_path, destination_file_path)
        if File.exist?(destination_file_path)
          source_version      = ProcessSettings::TargetedSettings.from_file(source_file_path, only_meta: true).version
          destination_version = ProcessSettings::TargetedSettings.from_file(destination_file_path, only_meta: true).version

          if Gem::Version.new(source_version) < Gem::Version.new(destination_version)
            FileUtils.rm_f(source_file_path) # clean up, remove left over file

            raise SourceVersionOlderError,
                  "source file '#{source_file_path}' is version #{source_version}"\
                  " and destination file '#{destination_file_path}' is version #{destination_version}"
          end
        end
      end
    end
  end
end
