# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/process_settings/testing/monitor'

describe ProcessSettings do
  before { described_class.instance = nil }

  describe '#instance' do
    let(:instance) { ProcessSettings::Testing::Monitor.new([], logger: Logger.new('/dev/null')) }

    subject { described_class.instance }

    describe 'when lazy loading' do
      before do
        expect_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with("`ProcessSettings::Monitor.instance` lazy create is deprecated and will be removed in v1.0. Assign a `FileMonitor` object to `ProcessSettings.instance =` instead.")
        expect_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with("`ProcessSettings::Monitor.instance` is deprecated and will be removed in v1.0. Assign a `FileMonitor` object to `ProcessSettings.instance =` instead.")
        expect(ProcessSettings::Monitor).to receive(:new_from_settings).and_return(instance)
      end

      it { should eq(instance) }
    end

    describe 'when set directly' do
      before { described_class.instance = instance }

      it { should eq(instance) }
    end
  end

  describe '#instance=' do
    subject { ProcessSettings::Monitor.instance_variable_get(:@instance) }

    describe 'when an AbstractMonitor object is provided' do
      let(:instance) { ProcessSettings::Testing::Monitor.new([], logger: Logger.new('/dev/null')) }
      before { described_class.instance = instance }
      it { should eq(instance) }
    end

    describe 'when nil is provided' do
      before { described_class.instance = nil }
      it { should be_nil }
    end

    describe 'when a non AbstractMonitor object is provided' do
      let(:expected_message) { "Invalid monitor of type String provided. Must be of type ProcessSettings::AbstractMonitor" }

      it 'raises an ArgumentError' do
        expect { described_class.instance = "notAbstract" }.to raise_error(ArgumentError, expected_message)
      end
    end
  end

  describe '#[]' do
    let(:instance) { ProcessSettings::Testing::Monitor.new([], logger: Logger.new('/dev/null')) }

    before do
      described_class.instance = instance
    end

    describe 'when called with defaults' do
      subject { described_class['gem', 'listen', 'log_level'] }

      before do
        expect(instance).to receive(:[]).with('gem', 'listen', 'log_level', dynamic_context: {}, required: true).and_return('info')
      end

      it { should eq('info') }
    end

    describe 'when called with keyword arguments' do
      subject { described_class['gem', 'listen', 'log_level', dynamic_context: { cuid: '1234' }, required: false] }

      before do
        expect(instance).to receive(:[]).with('gem', 'listen', 'log_level', dynamic_context: { cuid: '1234' }, required: false).and_return(nil)
      end

      it { should be_nil }
    end
  end
end
