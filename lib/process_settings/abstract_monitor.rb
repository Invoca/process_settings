# frozen_string_literal: true

require 'active_support'

require 'process_settings/targeted_settings'
require 'process_settings/hash_path'

module ProcessSettings
  class SettingsPathNotFound < StandardError; end

  OnChangeDeprecation = ActiveSupport::Deprecation.new('1.0', 'ProcessSettings::Monitor')

  class AbstractMonitor

    attr_reader :min_polling_seconds, :logger
    attr_reader :static_context, :statically_targeted_settings, :full_context_cache

    def initialize(logger:)
      @logger = logger or raise ArgumentError, "logger must be not be nil"
      @on_change_callbacks = []
      @when_updated_blocks = Set.new
      @static_context = {}
      @full_context_cache = {}
    end

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

      # Warn in the case where dynamic context was attempting to change a static value
      changes = dynamic_context.each_with_object({}) do |(key, dynamic_value), result|
        if static_context.has_key?(key)
          static_value = static_context[key]
          if static_value != dynamic_value
            result[key] = [static_value, dynamic_value]
          end
        end
      end

      changes.empty? or warn("WARNING: static context overwritten by dynamic!\n#{changes.inspect}")

      full_context = full_context_from_cache(dynamic_context)
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

    def full_context_from_cache(dynamic_context)
      if (full_context = full_context_cache[dynamic_context])
        full_context
      else
        dynamic_context.deep_merge(static_context).tap do |full_context|
          if full_context_cache.size <= 1000
            full_context_cache[dynamic_context] = full_context
          end
        end
      end
    end

    private

    class << self
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
  end
end
