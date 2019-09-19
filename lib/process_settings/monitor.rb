# frozen_string_literal: true

require_relative 'targeted_process_settings'
require_relative 'hash_path'
require 'psych'
require 'monotonic_tick_count'

module ProcessSettings
  class Monitor
    attr_reader :file_path, :min_polling_seconds
    attr_reader :static_context

    DEFAULT_MIN_POLLING_SECONDS = 5

    def initialize(file_path, min_polling_seconds: nil)
      @file_path = file_path
      @min_polling_seconds = min_polling_seconds || self.class.min_polling_seconds
      @on_change_callbacks = []
      @static_context = {}
    end

    # Registers the given callback block to be called when settings change.
    # This needs to be a quick method because it will be called on a borrowed thread (whichever polling code
    # noticed a change). Note that this means there is no guarantee for how soon it will be called after settings
    # change.
    def on_change(&callback)
      @on_change_callbacks << callback
    end

    # Returns the most recent settings from disk.
    # The disk file's mtime is polled no more frequently than DEFAULT_MIN_POLLING_SECONDS. If the mtime has changed,
    # the settings are reloaded from disk.
    def untargeted_settings
      time_now = now
      if poll_for_changes?(@last_looked_for_changes, time_now, @min_polling_seconds)
        @last_looked_for_changes = time_now
        if (changes = load_file_if_changed(@last_mtime, @file_path))
          @last_mtime, @untargetted_settings = changes
          notify_on_change
        end
      end

      @untargetted_settings
    end

    # Assigns a new static context. This clears the cache used by statically_targeted_settings so that
    # will be recomputed.
    def static_context=(context)
      @last_untargetted_settings = nil
      @static_context = context
    end

    # Returns the current process settings as a TargetAndProcessSettings given by applying the static context to the current untargeted settings
    # from disk.
    def statically_targeted_settings
      current_untargeted_settings = untargeted_settings

      if @last_untargetted_settings != current_untargeted_settings
        @statically_targetted_settings = current_untargeted_settings.with_static_context(@static_context)
        @last_untargetted_settings = current_untargeted_settings
      end

      @statically_targetted_settings
    end

    # Returns the process settings value at the given `path` using the given `dynamic_context`.
    # (It is assumed that the static context was already set through static_context=.)
    # Returns `nil` if nothing set at the given `path`.
    def targeted_value(path, dynamic_context)
      statically_targeted_settings.reduce(nil) do |result, target_and_settings|
        # find last value from matching targets
        if target_and_settings.target.target_key_matches?(dynamic_context)
          unless (value = HashPath.hash_at_path(target_and_settings.process_settings, path)).nil?
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

    # Returns a clock suitable for relative time comparisons. Wrapped in a method for easy stubbing.
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
      TargetedProcessSettings.from_array(json_doc)
    end
  end
end
