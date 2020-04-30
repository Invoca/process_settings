# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/testing/helpers'

describe ProcessSettings::Testing::Helpers do
  class TestClass
    include ProcessSettings::Testing::Helpers
  end

  let(:logger) { Logger.new(STDERR) }
  let(:test_instance) { TestClass.new }
  let(:combined_process_settings_fixture_path) { File.expand_path("../../../fixtures/production/combined_process_settings.yml", __dir__) }
  let(:default_process_settings) do
    ProcessSettings::FileMonitor.new(combined_process_settings_fixture_path, logger: logger)
  end

  describe '#stub_process_settings' do
    before do
      expect(test_instance).to receive(:default_process_settings).and_return(default_process_settings).at_least(1).times
      test_instance.stub_process_settings(settings_hash)
    end

    describe 'when a settings hash is provided' do
      let(:settings_hash) { { 'test' => { 'settings' => { 'id' => 12 } } } }

      it 'is targetted first' do
        expect(ProcessSettings['test', 'settings', 'id']).to eq(12)
      end

      it 'falls back to defaults' do
        expect(ProcessSettings['honeypot', 'answer_odds']).to eq(100)
      end
    end
  end

  describe '#default_process_settings' do
    let(:default_instance) { double('default instance') }
    subject { test_instance.default_process_settings }

    before { allow(ProcessSettings::Monitor).to receive(:instance).and_return(default_instance) }

    it { should be(default_instance) }
  end

  describe '#reset_process_settings' do
    let(:default_process_settings) { double("default_process_settings") }

    before { allow(test_instance).to receive(:default_process_settings).and_return(default_process_settings) }

    it 'resets the ProcessSettings::Monitor instance back to the default' do
      test_instance.reset_process_settings
      expect(ProcessSettings::Monitor.instance).to be(default_process_settings)
    end
  end
end
