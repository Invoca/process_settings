# frozen_string_literal: true

module ProcessSettings
  class Target
    include Comparable

    TRUE_JSON_DOC = {}.freeze

    attr_reader :json_doc

    def initialize(json_doc)
      @json_doc = json_doc
    end

    def target_key_matches?(context_hash)
      @json_doc == TRUE_JSON_DOC || self.class.target_key_matches?(@json_doc, context_hash)
    end

    def with_static_context(static_context_hash)
      new_json_doc = self.class.with_static_context(@json_doc, static_context_hash)
      self.class.new(new_json_doc)
    end

    def ==(rhs)
      json_doc == rhs.json_doc
    end

    def eql?(rhs)
      self == rhs
    end

    class << self
      def with_static_context(target_value, static_context_hash)
        case target_value
        when Array
          with_static_context_array(target_value, static_context_hash)
        when Hash
          with_static_context_hash(target_value, static_context_hash)
        when true, false
          !target_value == !static_context_hash
        when Regexp
          if static_context_hash.is_a?(String)
            static_context_hash.match?(target_value)
          else
            static_context_hash == target_value
          end
        else
          target_value == static_context_hash
        end
      end

      private

      def with_static_context_array(target_value, static_context_hash)
        target_value.any? do |value|
          with_static_context(value, static_context_hash)
        end
      end

      def with_static_context_hash(target_value, static_context_hash)
        result = target_value.reduce({}) do |hash, (key, value)|
          if static_context_hash.has_key?(key)
            context_at_key = static_context_hash[key]
            sub_value = with_static_context(value, context_at_key)
            case sub_value
            when true   # this hash entry is true, so omit it
            when false  # this hash entry is false, so hash is false
              return false
            else        # sub-key does not exist, so hash is false
              return false
            end
          else
            hash[key] = value
          end
          hash
        end

        if result.any?
          result
        else
          true
        end
      end

      public

      def target_key_matches?(target_value, context_hash)
        case target_value
        when Array
          target_value.any? { |value| target_key_matches?(value, context_hash) }
        when Hash
          target_value.all? do |key, value|
            if (context_at_key = context_hash[key])
              target_key_matches?(value, context_at_key)
            end
          end
        when true, false
          target_value
        when Regexp
          if context_hash.is_a?(String)
            context_hash.match?(target_value)
          else
            context_hash == target_value
          end
        else
          target_value == context_hash
        end
      end
    end

    class << self
      def true_target
        @true_target ||= new(TRUE_JSON_DOC)
      end
    end
  end
end
