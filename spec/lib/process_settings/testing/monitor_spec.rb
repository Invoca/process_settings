# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples_for_monitors'
require 'process_settings/testing/monitor'

describe ProcessSettings::Testing::Monitor do
  it_should_behave_like "Monitor", '<override>', Logger.new('/dev/null'), []
end
