# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples_for_monitors'
require 'process_settings/testing/monitor'

describe ProcessSettings::Testing::Monitor do
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
