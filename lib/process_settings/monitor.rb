# frozen_string_literal: true

require_relative 'file_monitor'

module ProcessSettings
  # DEPRECATED
  class Monitor < FileMonitor
    class << self
      attr_reader :logger, :file_path
      attr_writer :instance

      def file_path=(new_file_path)
        clear_instance

        @file_path = new_file_path
      end

      def new_from_settings
        file_path or raise ArgumentError, "#{self}::file_path must be set before calling instance method"
        logger or raise ArgumentError, "#{self}::logger must be set before calling instance method"
        new(file_path, logger: logger)
      end

      def clear_instance
        @instance = nil
        @default_instance = nil
      end

      def instance
        @instance ||= default_instance
      end

      def default_instance
        @default_instance ||= new_from_settings
      end

      def logger=(new_logger)
        @logger = new_logger
        Listen.logger ||= new_logger
      end
    end
  end
end
