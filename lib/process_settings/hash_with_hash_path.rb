# frozen_string_literal: true

require_relative 'hash_path'

module ProcessSettings
  class HashWithHashPath < Hash
    prepend HashPath
  end
end
