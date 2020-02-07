# frozen_string_literal: true

require_relative 'target'
require_relative 'settings'

module ProcessSettings
  # This class encapsulates a single YAML file with target and process_settings.
  class TargetAndSettings
    attr_reader :filename, :target, :settings

    def initialize(filename, target, settings)
      @filename = filename

      target.is_a?(Target) or raise ArgumentError, "target must be a ProcessTarget; got #{target.inspect}"
      @target = target

      settings.is_a?(Settings) or raise ArgumentError, "settings must be a ProcessSettings; got #{settings.inspect}"
      @settings = settings
    end

    def ==(rhs)
      to_json_doc == rhs.to_json_doc
    end

    def eql?(rhs)
      self == rhs
    end

    def to_json_doc
      {
        "target" => @target.json_doc,
        "settings" => @settings.json_doc
      }
    end

    class << self
      def from_json_docs(filename, target_json_doc, settings_json_doc)
        target_json_doc = Target.new(target_json_doc)

        settings = Settings.new(settings_json_doc)

        new(filename, target_json_doc, settings)
      end
    end

    # returns a copy of self with target simplified based on given static_context_hash (or returns self if there is no difference)
    def with_static_context(static_context_hash)
      new_target = target.with_static_context(static_context_hash)
      if new_target == @target
        self
      else
        self.class.new(@filename, new_target, @settings)
      end
    end
  end
end
