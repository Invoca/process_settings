# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples_for_monitors'
require 'process_settings/abstract_monitor'

class TestMonitor < ProcessSettings::AbstractMonitor
  def initialize(settings, logger: logger)
    super(logger: logger)
    @statically_targeted_settings = settings
  end
end

describe TestMonitor do
  it_should_behave_like(
    "AbstractMonitor",
    [
      ProcessSettings::TargetAndSettings.new(
        '<test_override>',
        ProcessSettings::Target.new({}),
        ProcessSettings::Settings.new('honeybadger' => { 'enabled' => true })
      )
    ],
    Logger.new('/dev/null'),
    ['honeybadger', 'enabled']
  )
end
