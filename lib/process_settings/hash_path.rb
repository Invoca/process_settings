# frozen_string_literal: true

module ProcessSettings
  # Module for mixing into `Hash` or other class with `[]` that you want to be able to index
  # with a hash path like:  hash['app.service_name' => 'frontend']
  module HashPath
    def [](key)
      if key.is_a?(Hash)
        HashPath.hash_at_path(self, key)
      else
        super
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

      def set_hash_at_path(hash, path)
        path.is_a?(Hash) or raise ArgumentError, "got unexpected non-hash value (#{hash[path]}"
        case path.size
        when 0
          hash
        when 1
          path_key, path_value = path.first
          if path_value.is_a?(Hash)
            set_hash_at_path(remaining_hash, remaining_path)
          else
            hash[path_key] = path_value
          end
        else
          raise ArgumentError, "path may have at most 1 key (got #{path.inspect})"
        end
        hash
      end
    end
  end
end
