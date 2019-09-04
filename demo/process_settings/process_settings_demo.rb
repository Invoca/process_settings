# frozen_string_literal: true

require 'contextual_logger'
require 'contextual_logger/process_settings_monitor'
require_relative 'config/process_settings_config'
require 'contextual_logger/stream_logger'
require 'contextual_logger/stream_logger_source'
require 'logger'




static_context = ARGV.reduce({}) do |hash, arg|
  key, value = arg.split('=', 2)
  value or raise ArgumentError, "args must be key=value (got #{arg.inspect})"
  hash[key] = value
  hash
end

ContextualLogger::ProcessSettingsMonitor.instance.static_context = static_context

static_context_symbols = static_context.reduce({}) { |h, (k, v)| h[k.to_sym] = v; h }

class CallSimulator
  include ContextualLogger::StreamLoggerSource

  attr_reader :logger

  log_stream_source :CallSimulator, streams: [:detail, :primes]

  def initialize(logger, static_context)
    @logger = logger
    @static_context = static_context
  end

  def run!
    counter = 0
    loop do
      puts "\nSettings:\n#{ContextualLogger::TargetedProcessSettings.new(ContextualLogger::ProcessSettingsMonitor.instance.current_statically_targeted_settings).to_yaml}\n"

      from = ['8056807000', '8056487708'][counter % 2]

      @logging_context = @static_context.merge(cdr: { 'from' => from, 'to' => '8005554321'})

      receive_call(from)
      sleep(5)
      counter += 1
    end
  end

  def receive_call(from)
    if ContextualLogger::ProcessSettingsMonitor.instance.targeted_value('reject_incoming_calls', @logging_context)
      @logger.info("REJECTED call from #{from}", @logging_context)
    else
      @logger.info("received call from #{from}", @logging_context)

      @logger.debug("MORE DETAIL ON RECEIVED CALL\n#{".... :: "*300}", @logging_context)

      log_stream(:primes, @logging_context) do |max|
        max = max.to_i.nonzero? || 1000
        "First #{max} primes are: #{primes(max)}"
      end
    end
  end

  private

  def primes(max)
    primes = (0...max).to_a

    primes[0] = primes[1] = nil

    primes.each do |p|
      p or next

      (p_squared = p*p) <= max or break

      p_squared.step(max, p) { |m| primes[m] = nil }
    end

    primes.compact
  end
end


raw_logger = Logger.new(STDOUT)
logger = ContextualLogger::StreamLogger.new(ContextualLogger.new(raw_logger))

ContextualLogger::ProcessSettingsMonitor.instance.on_change do |process_monitor|
  if (level_string = process_monitor.targeted_value({'logging' => 'level'}, {}))
    puts "\n******* #{level_string} ******"

    logger.level = level_string
  end
end

simulator = CallSimulator.new(logger, static_context_symbols)

simulator.run!
