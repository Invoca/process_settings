# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/process_settings'
require 'process_settings/stream_logger'
require 'process_settings/stream_logger_source'

class LoggingClientStub
  include ProcessSettings::StreamLoggerSource

  log_stream_source :SipBridge, streams: [:detail, :highlights]

  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def bridge
    log_stream(:detail) { "sending packets ... #{'detail here'}" }
  end
end

class StreamLoggerSpecLogStub
  def info(message)
  end

  def debug(message)
  end
end

describe ProcessSettings::StreamLoggerSource do
  describe "#stream" do
    before do
      @logger = StreamLoggerSpecLogStub.new
      @stream_logger = ProcessSettings::StreamLogger.new(ContextualLogger.new(@logger))
      @logging_client = LoggingClientStub.new(@stream_logger)
    end

    it "should call logger.info when source_stream is enabled" do
      expect(@stream_logger).to receive(:stream_enabled?).with({ 'SipBridge' => 'detail' }, {}) { true }
      expect(@stream_logger).to receive(:info).with("sending packets ... detail here")

      @logging_client.bridge
    end

    it "should not call logger.info when source_stream is enabled" do
      expect(@stream_logger).to receive(:stream_enabled?).with({ 'SipBridge' => 'detail' }, {}) { false }
      expect(@stream_logger).to_not receive(:info)

      @logging_client.bridge
    end
  end
end
