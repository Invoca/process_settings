# frozen_string_literal: true

module ProcessSettings
  class << self
    def plain_hash(json_doc)
      case json_doc
      when Hash
        result = {}
        json_doc.each { |key, value| result[key] = plain_hash(value) }
        result
      when Array
        json_doc.map { |value| plain_hash(value) }
      else
        if json_doc.respond_to?(:json_doc)
          plain_hash(json_doc.json_doc)
        else
          json_doc
        end
      end
    end
  end
end
