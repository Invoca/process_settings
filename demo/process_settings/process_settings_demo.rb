# frozen_string_literal: true

require_relative '../../lib/process_settings/process_settings_monitor'
require_relative 'config/process_settings_config'
require 'logger'

static_context = ARGV.reduce({}) do |hash, arg|
  key, value = arg.split('=', 2)
  value or raise ArgumentError, "args must be key=value (got #{arg.inspect})"
  hash[key] = value
  hash
end

ProcessSettings::ProcessSettingsMonitor.instance.static_context = static_context

static_context_symbols = static_context.reduce({}) { |h, (k, v)| h[k.to_sym] = v; h }

class CallSimulator
  def initialize(logger, static_context)
    @logger = logger
    @static_context = static_context
  end

  def run!
    counter = 0
    loop do
      puts "\nSettings:\n#{ProcessSettings::TargetedProcessSettings.new(ProcessSettings::ProcessSettingsMonitor.instance.statically_targeted_settings).to_yaml}\n"

      from = ['8056807000', '8056487708'][counter % 2]

      @logging_context = @static_context.merge(cdr: { 'from' => from, 'to' => '8005554321' })

      receive_call(from)
      sleep(5)
      counter += 1
    end
  end

  def receive_call(from)
    if ProcessSettings::ProcessSettingsMonitor.instance.targeted_value('reject_incoming_calls', @logging_context)
      @logger.info("REJECTED call from #{from}")
    else
      @logger.info("received call from #{from}")

      @logger.debug("MORE DETAIL ON RECEIVED CALL\n#{'.... :: ' * 30}")
    end
  end

  private

  def primes(max)
    result = (0...max).to_a

    result[0] = result[1] = nil

    result.each do |p|
      p or next

      (p_squared = p * p) <= max or break

      p_squared.step(max, p) { |m| result[m] = nil }
    end

    result.compact
  end
end

logger = Logger.new(STDOUT)

ProcessSettings::ProcessSettingsMonitor.instance.on_change do |process_monitor|
  if (level_string = process_monitor.targeted_value({ 'logging' => 'level' }, {}))
    puts "\n******* #{level_string} ******"

    logger.level = level_string
  end
end

simulator = CallSimulator.new(logger, static_context_symbols)

simulator.run!
