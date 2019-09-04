# frozen_string_literal: true

require_relative 'process_target'
require_relative 'process_settings'

module ProcessSettings
  class TargetAndProcessSettings
    attr_reader :target, :process_settings

    def initialize(target, settings)
      target.is_a?(ProcessTarget) or raise ArgumentError, "target must be a ProcessTarget; got #{target.inspect}"
      @target = target

      settings.is_a?(ProcessSettings) or raise ArgumentError, "settings must be a ProcessSettings; got #{settings.inspect}"
      @process_settings = settings
    end

    def to_json_doc
      {
        "target"    => @target.json_doc,
        "settings"  => @process_settings.json_doc
      }
    end

    class << self
      def from_json(target_json_doc, settings_json_doc)
        target_json_doc = ProcessTarget.new(target_json_doc)

        process_settings = ProcessSettings.new(settings_json_doc)

        new(target_json_doc, process_settings)
      end
    end

    # returns a copy of self with target simplified based on given static_context_hash (or returns self if there is no difference)
    def with_static_context(static_context_hash)
      new_target = target.with_static_context(static_context_hash)
      if new_target == @target
        self
      else
        self.class.new(new_target, @process_settings)
      end
    end
  end
end
