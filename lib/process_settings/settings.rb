# frozen_string_literal: true

require_relative 'hash_with_hash_path'

module ProcessSettings
  class Settings
    include Comparable

    attr_reader :json_doc

    def initialize(json_doc)
      json_doc.is_a?(Hash) or raise ArgumentError, "ProcessSettings must be a Hash; got #{json_doc.inspect}"

      AbstractMonitor.ensure_no_symbols(json_doc)

      @json_doc = HashWithHashPath[json_doc]
    end

    def ==(rhs)
      json_doc == rhs.json_doc
    end

    def eql?(rhs)
      self == rhs
    end
  end
end
