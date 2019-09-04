# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/process_settings'
require 'process_settings/stream_logger'
require 'process_settings/hash_with_hash_path'

class SipBridgeStub
  include ProcessSettings::StreamLoggerSource

  log_stream_source 'SipBridge', streams: ['detail', 'highlights']

  def bridge
    log_stream_info('detail') { "sending packets ... #{'detail here'}" }
  end
end

class StreamLoggerSpecLogStub
  def info(message)
  end

  def debug(message)
  end
end

describe ProcessSettings::StreamLogger do
  describe "#stream" do
    before do
      @logger = StreamLoggerSpecLogStub.new
      @stream_logger = described_class.new(ContextualLogger.new(@logger))
      class << @stream_logger
        def stream_enabled?(source_stream, _context)
          @source_stream_hash[source_stream]
        end
      end
    end

    it "should call logger.info when source_stream is enabled" do
      block_called = false
      expect(@stream_logger).to receive(:stream_enabled?).with({ 'SipBridge' => 'detail' }, {}) { true }
      expect(@stream_logger).to receive(:info).with("message")

      @stream_logger.stream({ 'SipBridge' => 'detail' }, {}) { block_called = true; "message" }

      expect(block_called).to be
    end

    it "should not call logger.info when source_stream is disabled" do
      expect(@stream_logger).to receive(:stream_enabled?).with({ 'SipBridge' => 'detail' }, {}) { false }
      expect(@logger).to_not receive(:info)

      block_called = false
      @stream_logger.stream({ 'SipBridge' => 'detail' }, {}) { block_called = true; "message" }

      expect(block_called).to_not be
    end
  end
end
