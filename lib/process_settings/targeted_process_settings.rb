# frozen_string_literal: true

require 'yaml'
require_relative 'target_and_process_settings'

module ProcessSettings
  class TargetedProcessSettings
    KEY_NAMES = ["filename", "target", "settings"].freeze

    attr_reader :targeted_settings_array

    def initialize(targeted_settings_array)
      targeted_settings_array.is_a?(Array) or raise ArgumentError, "targeted_settings_array must be an Array of Hashes; got #{targeted_settings_array.inspect}"
      targeted_settings_array.each do |target_and_process_settings|
        target_and_process_settings.is_a?(TargetAndProcessSettings) or
          raise ArgumentError, "targeted_settings_array entries must each be a TargetAndProcessSettings; got #{target_and_process_settings.inspect}"
      end

      @targeted_settings_array = targeted_settings_array
    end

    def to_json_doc
      @targeted_settings_array.map(&:to_json_doc)
    end

    def to_yaml
      to_json_doc.to_yaml
    end

    class << self
      def from_array(settings_array)
        settings_array.is_a?(Array) or raise ArgumentError, "settings_array must be an Array of Hashes; got #{settings_array.inspect}"
        end_found = false

        targeted_settings_array =
          settings_array.map do |settings_hash|
            settings_hash.is_a?(Hash) or raise ArgumentError, "settings_array entries must each be a Hash; got #{settings_hash.inspect}"

            end_found and raise ArgumentError, "\"END\" marker must be at end. (Got #{settings_hash.inspect} after.)"
            if settings_hash.has_key?("END")
              settings_hash == { "END" => true } or raise ArgumentError, "END marker must be solely { \"END\" => true }. (Got #{setings_hash.inspect}.)"
              end_found = true
              next
            end

            filename               = settings_hash["filename"]
            target_settings_hash   = settings_hash["target"] || true
            settings_settings_hash = settings_hash["settings"]

            settings_settings_hash or raise ArgumentError, "settings_array entries must each have 'settings' hash: #{settings_hash.inspect}"

            (extra_keys = settings_hash.keys - KEY_NAMES).empty? or
              raise ArgumentError, "settings_array entries must each have exactly these keys: #{KEY_NAMES.inspect}; got these extras: #{extra_keys.inspect}\nsettings_hash: #{settings_hash.inspect}"

            TargetAndProcessSettings.from_json_docs(filename, target_settings_hash, settings_settings_hash)
          end.compact

        new(targeted_settings_array)
      end
    end

    def matching_settings(context_hash)
      @targeted_settings_array.select do |target_and_process_settings|
        target_and_process_settings.target.target_key_matches?(context_hash)
      end
    end

    # returns the collection of targeted_settings with target simplified based on given static_context_hash
    # omits entries whose targeting is then false
    def with_static_context(static_context_hash)
      @targeted_settings_array.map do |target_and_process_settings|
        new_target_and_process_settings = target_and_process_settings.with_static_context(static_context_hash)
        new_target_and_process_settings if new_target_and_process_settings.target.json_doc
      end.compact
    end

    def settings_with_static_context(static_context_hash)
      result_settings =
        @settings_array.map do |target_and_settings|
          if (new_target = target.with_static_context(static_context_hash))
            TargetAndProcessSettings.new(new_target, target_and_settings.settings)
          end
        end.compact

      self.class.new(result_settings)
    end
  end
end
