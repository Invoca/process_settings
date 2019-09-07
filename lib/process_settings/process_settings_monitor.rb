# frozen_string_literal: true

require_relative 'targeted_process_settings'
require 'psych'
require 'monotonic_tick_count'

module ProcessSettings
  class ProcessSettingsMonitor
    attr_reader :file_path, :min_polling_seconds
    attr_accessor :static_context

    DEFAULT_MIN_POLLING_SECONDS = 5

    def initialize(file_path, min_polling_seconds: DEFAULT_MIN_POLLING_SECONDS)
      @file_path = file_path
      @min_polling_seconds = min_polling_seconds
      @on_change_callbacks = []
    end

    def on_change(&callback)
      @on_change_callbacks << callback
    end

    def current_untargeted_settings
      time_now = now
      if poll_for_changes?(@last_looked_for_changes, time_now, @min_polling_seconds)
        @last_looked_for_changes = time_now
        if (changes = load_file_if_changed(@last_mtime, @file_path))
          @last_mtime, @current_untargetted_settings = changes
          notify_on_change
        end
      end

      @current_untargetted_settings
    end

    def current_statically_targeted_settings
      current = current_untargeted_settings

      if !@current_statically_targetted_settings || @previous_untargetted_settings != current
        @current_statically_targetted_settings = current.with_static_context(static_context)
      end

      @current_statically_targetted_settings
    end

    def targeted_value(path, context)
      current_statically_targeted_settings.reduce(nil) do |result, target_and_settings|
        # find last value from matching targets
        if target_and_settings.target.target_key_matches?(context)
          unless (value = ProcessSettings::HashPath.hash_at_path(target_and_settings.process_settings, path)).nil?
            result = value
          end
        end
        result
      end
    end

    @min_polling_seconds = DEFAULT_MIN_POLLING_SECONDS

    class << self
      attr_accessor :file_path, :min_polling_seconds

      def clear_instance
        @instance = nil
      end

      def instance
        file_path or raise ArgumentError, "#{self}::file_path must be set before calling instance method"
        @instance ||= new(file_path, min_polling_seconds: min_polling_seconds)
      end
    end

    private

    def notify_on_change
      @on_change_callbacks.each do |callback|
        begin
          callback.call(self)
        rescue => ex
          warn("notify_on_change rescued exception:\n#{ex.class}: #{ex.message}")
        end
      end
    end

    def now
      MonotonicTickCount.now
    end

    def poll_for_changes?(last_looked_for_changes, time_now, min_polling_seconds)
      last_looked_for_changes.nil? || time_now > (last_looked_for_changes + min_polling_seconds)
    end

    # if changed, returns [mtime, file contents]
    # if not changed, returns nil
    def load_file_if_changed(last_mtime, file_path)
      mtime = current_mtime(file_path)
      if mtime != last_mtime
        [mtime, load_file(file_path)]
      end
    end

    def current_mtime(file_path)
      File.stat(file_path).mtime
    end

    def load_file(file_path)
      json_doc = Psych.load_file(file_path)
      TargetedProcessSettings.from_json(json_doc)
    end
  end
end
