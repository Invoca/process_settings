# frozen_string_literal: true

require 'active_support'
require 'listen'
require 'psych'

require 'process_settings/abstract_monitor'
require 'process_settings/targeted_settings'
require 'process_settings/hash_path'

module ProcessSettings
  class FileMonitor < AbstractMonitor
    class << self
      attr_accessor :file_path

      def default_instance
        file_path or raise ArgumentError, "#{self}::file_path must be set before calling instance method"
        logger or raise ArgumentError, "#{self}::logger must be set before calling instance method"
        new(file_path, logger: logger)
      end
    end

    attr_reader :file_path, :untargeted_settings

    def initialize(file_path, logger:)
      super(logger: logger)

      @file_path = File.expand_path(file_path)
      @last_statically_targetted_settings = nil
      @untargeted_settings = nil
      @last_untargetted_settings = nil

      start
    end

    # starts listening for changes
    # Note: This method creates a new thread that will be monitoring for changes
    #       do to the nature of how the Listen gem works, there is no record of
    #       existing threads, calling this mutliple times will result in spinning off
    #       multiple listen threads and will have unknow effects
    def start
      path = File.dirname(file_path)

      # to eliminate any race condition:
      # 1. set up file watcher
      # 2. start it (this should trigger if any changes have been made since (1))
      # 3. load the file

      @listener = file_change_notifier.to(path) do |modified, added, _removed|
        if modified.include?(file_path) || added.include?(file_path)
          logger.info("ProcessSettings::Monitor file #{file_path} changed. Reloading.")
          load_untargeted_settings

          load_statically_targeted_settings
        end
      end

      unless ENV['DISABLE_LISTEN_CHANGE_MONITORING']
        @listener.start
      end

      load_untargeted_settings
      load_statically_targeted_settings
    end

    # stops listening for changes
    def stop
      @listener&.stop
    end

    private

    # Loads the most recent settings from disk
    def load_untargeted_settings
      new_untargeted_settings = load_file(file_path)
      old_version = @untargeted_settings&.version
      new_version = new_untargeted_settings.version
      @untargeted_settings = new_untargeted_settings
      logger.info("ProcessSettings::Monitor#load_untargeted_settings loaded version #{new_version}#{" to replace version #{old_version}" if old_version}")
    end

    # Loads the latest untargeted settings from disk. Returns the current process settings as a TargetAndProcessSettings given
    # by applying the static context to the current untargeted settings from disk.
    # If these have changed, borrows this thread to call notify_on_change and call_when_updated_blocks.
    def load_statically_targeted_settings(force_retarget: false)
      if force_retarget || @last_untargetted_settings != @untargeted_settings
        @last_untargetted_settings = @untargeted_settings
        @statically_targeted_settings = @untargeted_settings.with_static_context(@static_context)
        if @last_statically_targetted_settings != @statically_targeted_settings
          @last_statically_targetted_settings = @statically_targeted_settings

          notify_on_change
          call_when_updated_blocks
        end
      end
    end

    def load_file(file_path)
      TargetedSettings.from_file(file_path)
    end

    def file_change_notifier
      Listen
    end
  end
end
