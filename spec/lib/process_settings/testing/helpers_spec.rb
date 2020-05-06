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
      expect(ProcessSettings::FileMonitor).to receive(:default_instance).and_return(default_process_settings).at_least(1).times
      test_instance.stub_process_settings(settings_hash)
    end

    describe 'when a settings hash is provided' do
      let(:settings_hash) { { 'test' => { 'settings' => { 'id' => 12 } } } }

      describe 'when accessing an override' do
        subject { ProcessSettings['test', 'settings', 'id'] }
        it { should eq(12) }
      end

      describe 'when accessing a default settings' do
        subject { ProcessSettings['honeypot', 'answer_odds'] }
        it { should eq(100) }
      end
    end
  end
end
