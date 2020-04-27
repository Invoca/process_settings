# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/testing/helpers'

describe ProcessSettings::Testing::Helpers do
  describe '#stub_process_settings' do
    before { described_class.stub_process_settings(settings_hash) }

    describe 'when a settings hash is provided' do
      let(:settings_hash) { { test: { settings: { enabled: true } } } }

      it 'sets the setting with targetting true' do
        expect(ProcessSettings['test', 'settings', 'enabled']).to eq(true)
      end
    end
  end

  describe '#default_process_settings' do
    subject { described_class.default_process_settings }

    it { should be_a(ProcessSettings::Monitor) }
    it { should_not be_a(ProcessSettings::Testing::Monitor) }
  end

  describe '#reset_process_settings' do
    let(:default_process_settings) { ProcessSettings::Monitor.instance }

    before { allow(described_class).to receive(:default_process_settings).and_return(default_process_settings) }

    it 'resets the ProcessSettings::Monitor instance back to the default' do
      expect(ProcessSettings::Monitor.instance).to eq(default_process_settings)

      ProcessSettings::Monitor.instance = "hello world"
      expect(ProcessSettings::Monitor.instance).to_not eq(default_process_settings)

      described_class.reset_process_settings
      expect(ProcessSettings::Monitor.instance).to eq(default_process_settings)
    end
  end
end
