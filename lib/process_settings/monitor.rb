# frozen_string_literal: true

require 'active_support'
require 'active_support/deprecation'

require_relative 'file_monitor'

module ProcessSettings
  # DEPRECATED
  class Monitor < FileMonitor
    class << self
      attr_reader :logger, :file_path
      attr_writer :instance

      def file_path=(new_file_path)
        ActiveSupport::Deprecation.warn("ProcessSettings::Monitor.file_path= is deprecated and will be removed in v1.0.")
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
        ActiveSupport::Deprecation.warn("ProcessSettings::Monitor.default_instance is deprecated and will be removed in v1.0. Use ProcessSettings.instance instead.")
        @default_instance ||= new_from_settings
      end

      def logger=(new_logger)
        ActiveSupport::Deprecation.warn("ProcessSettings::Monitor.logger is deprecated and will be removed in v1.0.")
        @logger = new_logger
        Listen.logger ||= new_logger
      end

      deprecate :logger, :logger=, :file_path, :file_path=, deprecator: ActiveSupport::Deprecation.new('1.0', 'ProcessSettings')
    end

    deprecate :initialize, deprecator: ActiveSupport::Deprecation.new('1.0', 'ProcessSettings')
  end
end
