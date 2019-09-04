# frozen_string_literal: true

module ProcessSettings
  # Module for mixing into `Hash` or other class with `[]` that you want to be able to index
  # with a hash path like:  hash.mine('honeypot', 'answer_odds')
  module HashPath
    # returns the value found at the given path
    # if the path is not found:
    #   if a block is given, it is called and its value returned (may also raise an exception from the block)
    #   else, the not_found_value: is returned
    def mine(*path_array, not_found_value: nil)
      path_array.is_a?(Enumerable) && path_array.size > 0 or raise ArgumentError, "path must be 1 or more keys; got #{path_array.inspect}"
      path_array.reduce(self) do |hash, key|
        if hash.has_key?(key)
          hash[key]
        else
          if block_given?
            break yield
          else
            break not_found_value
          end
        end
      end
    end

    class << self
      def hash_at_path(hash, path)
        if path.is_a?(Hash)
          case path.size
          when 0
            hash
          when 1
            path_key, path_value = path.first
            if (remaining_hash = hash[path_key])
              remaining_path = path_value
              hash_at_path(remaining_hash, remaining_path)
            end
          else
            raise ArgumentError, "path may have at most 1 key (got #{path.inspect})"
          end
        else
          hash[path]
        end
      end
    end
  end
end
