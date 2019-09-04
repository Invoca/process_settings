# frozen_string_literal: true

require 'active_support/concern'

module ProcessSettings::StreamLoggerSource
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :log_stream_source_string, :log_stream_strings

    def log_stream_source(source, streams)
      @log_stream_source_string = source.to_s
      @log_stream_strings = Array(streams).map(&:to_s)
    end
  end

  class << self
    def new(logger)
      logger.extend(self)
    end
  end

  def log_stream(stream, **context, &block)
    # TODO: assert stream is in log_stream_strings? -Colin
    stream_string = stream.to_s
    logger.stream({self.class.log_stream_source_string => stream_string.to_s}, context, &block)
  end
end
