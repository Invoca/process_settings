# frozen_string_literal: true

begin
  require 'rb-inotify'
rescue FFI::NotFoundError
end

module ProcessSettings
end

require 'process_settings/monitor'
