# frozen_string_literal: true

require_relative 'hash_with_hash_path'

module ProcessSettings
  class ProcessSettings
    include Comparable

    attr_reader :json_doc

    def initialize(json_doc)
      json_doc.is_a?(Hash) or raise ArgumentError, "ProcessSettings must be a Hash; got #{json_doc.inspect}"

      @json_doc = HashWithHashPath[json_doc]
    end

    def <=>(rhs)
      json_doc <=> rhs.json_doc
    end

    def eql?(rhs)
      self == rhs
    end

    def [](key)
      @json_doc[key]
    end
  end
end
