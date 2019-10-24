# frozen_string_literal: true

require_relative 'targeted_settings'
require_relative 'hash_path'
require 'psych'
require 'listen'
require 'active_support'

module ProcessSettings
  class Monitor
    attr_reader :file_path, :min_polling_seconds
    attr_reader :static_context, :untargeted_settings, :statically_targeted_settings

    DEFAULT_MIN_POLLING_SECONDS = 5

    def initialize(file_path, logger:)
      @file_path = File.expand_path(file_path)
      @logger = logger
      @on_change_callbacks = []
      @static_context = {}

      # to eliminate any race condition:
      # 1. set up file watcher
      # 2. start it (this should trigger if any changes have been made since (1))
      # 3. load the file

      path = File.dirname(@file_path)

      @listener = file_change_notifier.to(path) do |modified, _added, _removed|
        if modified.include?(@file_path)
          @logger.info("ProcessSettings::Monitor file #{@file_path} changed. Reloading.")
          load_untargeted_settings
        end
      end

      @listener.start

      load_untargeted_settings

      statically_targeted_settings # so that notify_on_change will be called if any changes
    end

    # stops listening for changes
    def stop
      @listener.stop
    end

    # Registers the given callback block to be called when settings change.
    # These are run using the shared thread that monitors for changes so be courteous and don't monopolize it!
    def on_change(&callback)
      @on_change_callbacks << callback
    end

    # Loads the most recent settings from disk and returns them.
    def load_untargeted_settings
      @untargeted_settings = load_file(file_path)
    end

    # Assigns a new static context. Recomputes statically_targeted_settings.
    def static_context=(context)
      @static_context = context

      statically_targeted_settings(force: true)
    end

    # Loads the latest untargeted settings from disk. Returns the current process settings as a TargetAndProcessSettings given
    # by applying the static context to the current untargeted settings from disk.
    # If these have changed, borrows this thread to call notify_on_change.
    def statically_targeted_settings(force: false)
      if force || @last_untargetted_settings != @untargeted_settings
        @statically_targeted_settings = @untargeted_settings.with_static_context(@static_context)
        @last_untargetted_settings = @untargeted_settings

        notify_on_change
      end

      @statically_targeted_settings
    end

    # Returns the process settings value at the given `path` using the given `dynamic_context`.
    # (It is assumed that the static context was already set through static_context=.)
    # Returns `nil` if nothing set at the given `path`.
    def targeted_value(path, dynamic_context)
      # Merging the static context in is necessary to make sure that the static context isn't shifting
      # this can be rather costly to do every time if the dynamic context is not changing
      # TODO: Warn in the case where dynamic context was attempting to change a static value
      # TODO: Cache the last used dynamic context as a potential optimization to avoid unnecessary deep merges
      full_context = dynamic_context.deep_merge(static_context)
      statically_targeted_settings.reduce(nil) do |result, target_and_settings|
        # find last value from matching targets
        if target_and_settings.target.target_key_matches?(full_context)
          unless (value = HashPath.hash_at_path(target_and_settings.process_settings, path)).nil?
            result = value
          end
        end
        result
      end
    end

    class << self
      attr_accessor :file_path
      attr_reader :logger

      def clear_instance
        @instance = nil
      end

      def instance
        file_path or raise ArgumentError, "#{self}::file_path must be set before calling instance method"
        logger or raise ArgumentError, "#{self}::logger must be set before calling instance method"
        @instance ||= new(file_path, logger: logger)
      end

      def logger=(new_logger)
        @logger = new_logger
        Listen.logger = new_logger
      end
    end

    private

    def notify_on_change
      @on_change_callbacks.each do |callback|
        begin
          callback.call(self)
        rescue => ex
          logger.error("ProcessSettings::Monitor#notify_on_change rescued exception:\n#{ex.class}: #{ex.message}")
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
