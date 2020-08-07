# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/testing/helpers'

describe ProcessSettings::Testing::Helpers do
  class TestClassRSpec
    @after_blocks = []

    class << self
      attr_reader :after_blocks

      def after(&block)
        after_blocks << block
      end
    end

    def call_after_block
      instance_exec(&self.class.after_blocks.first)
    end

    include ProcessSettings::Testing::Helpers
  end

  class TestClassMinitest
    class << self
      def after_blocks
        Array(instance_method(:teardown))
      end
    end

    def call_after_block
      self.class.after_blocks.first.bind(self).call
    end

    include ProcessSettings::Testing::Helpers
  end

  let(:logger) { Logger.new('/dev/null') }
  let(:test_instance) { TestClassRSpec.new }
  let(:combined_process_settings_fixture_path) { File.expand_path("../../../fixtures/production/combined_process_settings.yml", __dir__) }
  let(:initial_process_settings) do
    ProcessSettings::FileMonitor.new(combined_process_settings_fixture_path, logger: logger)
  end

  RSpec.shared_examples "defines after block" do
    it 'defines an after block' do
      expect(test_klass.after_blocks.size).to eq(1)
      test_instance = test_klass.new
      ProcessSettings.instance = initial_process_settings
      expect(test_instance.initial_instance).to eq(initial_process_settings)
      ProcessSettings.instance = nil
      test_instance.call_after_block
      expect(ProcessSettings.instance).to eq(initial_process_settings)
    end
  end

  describe 'when included in rspec' do
    let(:test_klass) { TestClassRSpec }

    include_examples "defines after block"
  end

  describe 'when included in minitest' do
    let(:test_klass) { TestClassMinitest }

    include_examples "defines after block"
  end

  describe '#stub_process_settings' do
    before do
      ProcessSettings.instance = initial_process_settings
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
