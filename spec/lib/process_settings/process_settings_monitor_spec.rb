# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'process_settings/process_settings_monitor'

describe ProcessSettings::ProcessSettingsMonitor do
  SETTINGS_PATH = "./settings.yml"
  SAMPLE_SETTINGS = [{ 'target' => true, 'settings' => { 'sip' => true } }].freeze
  EAST_SETTINGS = [{ 'target' => { 'region' => 'east' }, 'settings' => { 'reject_incoming_calls' => true } },
                   { 'target' => true, 'settings' => { 'sip' => true } }].freeze
  EMPTY_SAMPLE_SETTINGS = [{ 'target' => true, 'settings' => {} }].freeze
  SAMPLE_SETTINGS_YAML = SAMPLE_SETTINGS.to_yaml
  EAST_SETTINGS_YAML = EAST_SETTINGS.to_yaml
  EMPTY_SAMPLE_SETTINGS_YAML = EMPTY_SAMPLE_SETTINGS.to_yaml

  describe "#initialize" do
    it "should default min_polling_seconds to 5" do
      process_monitor = described_class.new(SETTINGS_PATH)
      expect(process_monitor.instance_variable_get(:@min_polling_seconds)).to eq(5)
    end
  end

  describe ".instance method" do
    before do
      described_class.clear_instance
    end

    it "should raise an exception if not configured" do
      described_class.file_path = nil

      expect do
        described_class.instance
      end.to raise_exception(ArgumentError, /::file_path must be set before calling instance method/)
    end

    it "should return a global instance" do
      described_class.file_path = "./process_settings.yml"

      instance_1 = described_class.instance
      instance_2 = described_class.instance

      expect(instance_1).to be_kind_of(described_class)
      expect(instance_1.object_id).to eq(instance_2.object_id)

      expect(instance_1.min_polling_seconds).to eq(5)
    end

    it "should use the configured min_polling_seconds" do
      described_class.file_path = "./process_settings.yml"
      described_class.min_polling_seconds = 20

      instance_1 = described_class.instance
      instance_2 = described_class.instance

      expect(instance_1).to be_kind_of(described_class)
      expect(instance_1.object_id).to eq(instance_2.object_id)

      expect(instance_1.min_polling_seconds).to eq(20)
    end
  end

  describe "#current_untargetted_settings" do
    before do
      File.write(SETTINGS_PATH, SAMPLE_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "should read from disk the first time" do
      process_monitor = described_class.new(SETTINGS_PATH)
      matching_settings = process_monitor.current_untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.target.json_doc).to eq(SAMPLE_SETTINGS.first['target'])
      expect(matching_settings.first.process_settings.instance_variable_get(:@json_doc)).to eq(SAMPLE_SETTINGS.first['settings'])
    end

    it "should not re-read from disk immediately" do
      process_monitor = described_class.new(SETTINGS_PATH)
      matching_settings = process_monitor.current_untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.process_settings.json_doc).to eq(SAMPLE_SETTINGS.first['settings'])

      File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)

      matching_settings = process_monitor.current_untargeted_settings.matching_settings({})
      expect(matching_settings.first.process_settings.json_doc).to eq(SAMPLE_SETTINGS.first['settings'])
    end

    it "should re-read from disk after the min_polling_interval" do
      process_monitor = described_class.new(SETTINGS_PATH, min_polling_seconds: 0.1)
      matching_settings = process_monitor.current_untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.process_settings.json_doc).to eq(SAMPLE_SETTINGS.first['settings'])

      File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)

      sleep(0.2)

      matching_settings = process_monitor.current_untargeted_settings.matching_settings({})
      expect(matching_settings.first.process_settings.json_doc).to eq({})
    end
  end

  describe "#current_targeted_settings" do
    before do
      File.write(SETTINGS_PATH, EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "should keep all entries when targeted" do
      process_monitor = described_class.new(SETTINGS_PATH)
      process_monitor.static_context = { 'region' => 'east' }

      result = process_monitor.current_statically_targeted_settings
      settings = result.map { |settings| settings.process_settings.json_doc }

      expect(settings).to eq([{ 'reject_incoming_calls' => true }, { 'sip' => true }])
    end

    it "should keep subset of targeted entries" do
      process_monitor = described_class.new(SETTINGS_PATH)
      process_monitor.static_context = { 'region' => 'west' }

      result = process_monitor.current_statically_targeted_settings
      settings = result.map { |settings| settings.process_settings.json_doc }

      expect(settings).to eq([{ 'sip' => true }])
    end
  end
end
