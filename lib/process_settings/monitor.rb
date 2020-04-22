# frozen_string_literal: true

require_relative 'targeted_settings'
require_relative 'hash_path'
require 'psych'
require 'listen'
require 'active_support'

module ProcessSettings
  class SettingsPathNotFound < StandardError; end

  OnChangeDeprecation = ActiveSupport::Deprecation.new('1.0', 'ProcessSettings::Monitor')

  class Monitor
    attr_reader :file_path, :min_polling_seconds, :logger
    attr_reader :static_context, :untargeted_settings, :statically_targeted_settings

    DEFAULT_MIN_POLLING_SECONDS = 5

    def initialize(file_path, logger:)
      @file_path = File.expand_path(file_path)
      @logger = logger
      @on_change_callbacks = []
      @when_updated_blocks = Set.new
      @static_context = {}
      @last_statically_targetted_settings = nil
      @untargeted_settings = nil
      @last_untargetted_settings = nil
      @last_untargetted_settings = nil

      start
    end

    # []
    #
    # This is the main entry point for looking up settings on the Monitor instance.
    #
    # @example
    #
    # ['path', 'to', 'setting']
    #
    # will return 42 in this example settings YAML:
    # +code+
    #   path:
    #     to:
    #       setting:
    #         42
    # +code+
    #
    # @param [Array(String)] path The path of one or more strings.
    #
    # @param [Hash] dynamic_context Optional dynamic context hash. It will be merged with the static context.
    #
    # @param [boolean] required If true (default) will raise `SettingsPathNotFound` if not found; otherwise returns `nil` if not found.
    #
    # @return setting value
    def [](*path, dynamic_context: {}, required: true)
      targeted_value(*path, dynamic_context: dynamic_context, required: required)
    end

    # starts listening for changes
    # Note: This method creates a new thread that will be monitoring for changes
    #       do to the nature of how the Listen gem works, there is no record of
    #       existing threads, calling this mutliple times will result in spinning off
    #       multiple listen threads and will have unknow effects
    def start
      path = File.dirname(@file_path)

      # to eliminate any race condition:
      # 1. set up file watcher
      # 2. start it (this should trigger if any changes have been made since (1))
      # 3. load the file

      @listener = file_change_notifier.to(path) do |modified, added, _removed|
        if modified.include?(@file_path) || added.include?(@file_path)
          @logger.info("ProcessSettings::Monitor file #{@file_path} changed. Reloading.")
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

    # Idempotently adds the given block to the when_updated collection
    # calls the block first unless initial_update: false is passed
    # returns a handle (the block itself) which can later be passed into cancel_when_updated
    def when_updated(initial_update: true, &block)
      if @when_updated_blocks.add?(block)
        if initial_update
          begin
            block.call(self)
          rescue => ex
            logger.error("ProcessSettings::Monitor#when_updated rescued exception during initialization:\n#{ex.class}: #{ex.message}")
          end
        end
      end

      block
    end

    # removes the given when_updated block identified by the handle returned from when_updated
    def cancel_when_updated(handle)
      @when_updated_blocks.delete_if { |callback| callback.eql?(handle) }
    end

    # Registers the given callback block to be called when settings change.
    # These are run using the shared thread that monitors for changes so be courteous and don't monopolize it!
    # @deprecated
    def on_change(&callback)
      @on_change_callbacks << callback
    end
    deprecate on_change: :when_updated, deprecator: OnChangeDeprecation

    # Assigns a new static context. Recomputes statically_targeted_settings.
    # Keys must be strings or integers. No symbols.
    def static_context=(context)
      self.class.ensure_no_symbols(context)

      @static_context = context

      load_statically_targeted_settings(force_retarget: true)
    end

    # Returns the process settings value at the given `path` using the given `dynamic_context`.
    # (It is assumed that the static context was already set through static_context=.)
    # If nothing set at the given `path`:
    #   if required, raises SettingsPathNotFound
    #   else returns nil
    def targeted_value(*path, dynamic_context:, required: true)
      # Merging the static context in is necessary to make sure that the static context isn't shifting
      # this can be rather costly to do every time if the dynamic context is not changing
      # TODO: Warn in the case where dynamic context was attempting to change a static value
      # TODO: Cache the last used dynamic context as a potential optimization to avoid unnecessary deep merges
      # TECH-4402 was created to address these todos
      full_context = dynamic_context.deep_merge(static_context)
      result = statically_targeted_settings.reduce(:not_found) do |latest_result, target_and_settings|
        # find last value from matching targets
        if target_and_settings.target.target_key_matches?(full_context)
          if (value = target_and_settings.settings.json_doc.mine(*path, not_found_value: :not_found)) != :not_found
            latest_result = value
          end
        end
        latest_result
      end

      if result == :not_found
        if required
          raise SettingsPathNotFound, "no settings found for path #{path.inspect}"
        else
          nil
        end
      else
        result
      end
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

    class << self
      attr_accessor :file_path
      attr_reader :logger
      attr_writer :instance

      def clear_instance
        @instance = nil
      end

      def instance
        @instance ||= begin
                        file_path or raise ArgumentError, "#{self}::file_path must be set before calling instance method"
                        logger or raise ArgumentError, "#{self}::logger must be set before calling instance method"
                        new(file_path, logger: logger)
                      end
      end

      def logger=(new_logger)
        @logger = new_logger
        Listen.logger ||= new_logger
      end

      def ensure_no_symbols(value)
        case value
        when Symbol
          raise ArgumentError, "symbol value #{value.inspect} found--should be String"
        when Hash
          value.each do |k, v|
            k.is_a?(Symbol) and raise ArgumentError, "symbol key #{k.inspect} found--should be String"
            ensure_no_symbols(v)
          end
        when Array
          value.each { |v| ensure_no_symbols(v) }
        end
      end
    end

    # Calls all registered on_change callbacks. Rescues any exceptions they may raise.
    # Note: this method can be re-entrant to the class; the on_change callbacks may call right back into these methods.
    # Therefore it's critical to finish all transitions and release any resources before calling this method.
    def notify_on_change
      @on_change_callbacks.each do |callback|
        begin
          callback.call(self)
        rescue => ex
          logger.error("ProcessSettings::Monitor#notify_on_change rescued exception:\n#{ex.class}: #{ex.message}")
        end
      end
    end

    def call_when_updated_blocks
      @when_updated_blocks.each do |block|
        begin
          block.call(self)
        rescue => ex
          logger.error("ProcessSettings::Monitor#call_when_updated_blocks rescued exception:\n#{ex.class}: #{ex.message}")
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
