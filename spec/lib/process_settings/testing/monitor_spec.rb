# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/testing/monitor'

describe ProcessSettings::Testing::Monitor do
  let(:settings_array) { [] }
  let(:logger) { Logger.new('/dev/null') }
  let(:test_monitor) { described_class.new(settings_array, logger: logger) }

  # TODO: This is the perfect place to use SharedExamples in order to state that
  #       this ProcessSettings::Testing::Monitor should behave like ProcessSettings::Monitor
  describe '#initialize' do
    subject { test_monitor }

    it { should be_a(ProcessSettings::Monitor) }
  end

  describe '#logger' do
    subject { test_monitor.logger }

    it { should eq(logger) }
  end

  describe '#file_path' do
    subject { test_monitor.file_path }

    it { should eq('<override>') }
  end

  describe '#static_context' do
    subject { test_monitor.static_context }

    it { should eq({}) }
  end

  describe '#load_statically_targetted_settings' do
    describe 'with default args (force_retarget: false)' do
      subject { test_monitor.load_statically_targetted_settings }

      it { should eq(settings_array) }
    end

    describe 'with force_retarget: true' do
      subject { test_monitor.load_statically_targetted_settings(force_retarget: true) }

      it { should eq(settings_array) }
    end

    describe 'with force_retarget: false' do
      subject { test_monitor.load_statically_targetted_settings(force_retarget: false) }

      it { should eq(settings_array) }
    end
  end
end
