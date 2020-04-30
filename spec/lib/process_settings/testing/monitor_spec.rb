# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples_for_monitors'
require 'process_settings/testing/monitor'

describe ProcessSettings::Testing::Monitor do
  it_should_behave_like "Monitor", '<override>', Logger.new('/dev/null'), []

  describe 'testing overrides' do
    let(:settings) { [] }
    let(:logger) { Logger.new('/dev/null') }
    let(:test_monitor) { described_class.new(settings, logger: logger) }

    describe '#load_statically_targetted_settings' do
      describe 'with default args (force_retarget: false)' do
        subject { test_monitor.load_statically_targetted_settings }

        it { should eq(settings) }
      end

      describe 'with force_retarget: true' do
        subject { test_monitor.load_statically_targetted_settings(force_retarget: true) }

        it { should eq(settings) }
      end

      describe 'with force_retarget: false' do
        subject { test_monitor.load_statically_targetted_settings(force_retarget: false) }

        it { should eq(settings) }
      end
    end
  end
end
