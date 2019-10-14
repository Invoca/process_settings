# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'process_settings/monitor'

describe ProcessSettings::Monitor do
  SETTINGS_PATH = "./settings.yml"
  SAMPLE_SETTINGS = [{ 'target' => true, 'settings' => { 'sip' => true } }, { 'meta' => { 'version' => 19, 'END' => true } }].freeze
  EAST_SETTINGS = [{ 'target' => { 'region' => 'east' }, 'settings' => { 'reject_call' => true } },
                   { 'target' => true, 'settings' => { 'sip' => true } },
                   { 'target' => { 'caller_id' => ['+18003334444', '+18887776666']}, 'settings' => { 'reject_call' => false }},
                   { 'meta' => { 'version' => 19, 'END' => true }}].freeze
  EMPTY_SAMPLE_SETTINGS = [{ 'target' => true, 'settings' => {} }, { 'meta' => { 'version' => 19, 'END' => true }}].freeze
  SAMPLE_SETTINGS_YAML = SAMPLE_SETTINGS.to_yaml
  EAST_SETTINGS_YAML = EAST_SETTINGS.to_yaml
  EMPTY_SAMPLE_SETTINGS_YAML = EMPTY_SAMPLE_SETTINGS.to_yaml

  describe "#initialize" do
    before do
      File.write(SETTINGS_PATH, SAMPLE_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "defaults to empty static_context" do
      process_monitor = described_class.new(SETTINGS_PATH)
      expect(process_monitor.static_context).to eq({})
    end
  end

  describe "class methods" do
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
        described_class.file_path = "./spec/fixtures/production/combined_process_settings.yml"

        instance_1 = described_class.instance
        instance_2 = described_class.instance

        expect(instance_1).to be_kind_of(described_class)
        expect(instance_1.object_id).to eq(instance_2.object_id)
      end
    end
  end

  describe "#untargeted_settings" do
    before do
      File.write(SETTINGS_PATH, SAMPLE_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "should read from disk the first time" do
      process_monitor = described_class.new(SETTINGS_PATH)
      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.target.json_doc).to eq(SAMPLE_SETTINGS.first['target'])
      expect(matching_settings.first.process_settings.instance_variable_get(:@json_doc)).to eq(SAMPLE_SETTINGS.first['settings'])
    end

    it "should not re-read from disk immediately" do
      process_monitor = described_class.new(SETTINGS_PATH)
      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.process_settings.json_doc).to eq(SAMPLE_SETTINGS.first['settings'])

      File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)

      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.first.process_settings.json_doc).to eq(SAMPLE_SETTINGS.first['settings'])
    end

    it "should re-read from disk when watcher triggered" do
      process_monitor = described_class.new(SETTINGS_PATH)
      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.process_settings.json_doc).to eq(SAMPLE_SETTINGS.first['settings'])

      File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)

      process_monitor.instance_variable_get(:@file_change_notifier).trigger_watchers

      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.first.process_settings.json_doc).to eq({})
    end
  end

  describe "#statically_targeted_settings" do
    let(:process_monitor) { described_class.new(SETTINGS_PATH) }

    before do
      File.write(SETTINGS_PATH, EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "keeps all entries when targeted" do
      process_monitor.static_context = { 'region' => 'east' }

      result = process_monitor.statically_targeted_settings
      settings = result.map { |s| s.process_settings.json_doc }

      expect(settings).to eq([{ 'reject_call' => true }, { 'sip' => true }, {'reject_call' => false}])
    end

    it "keeps subset of targeted entries" do
      process_monitor.static_context = { 'region' => 'west' }

      result = process_monitor.statically_targeted_settings
      settings = result.map { |s| s.process_settings.json_doc }

      expect(settings).to eq([{ 'sip' => true }, {"reject_call" => false}])
    end

    it "recomputes targeting if static_context changes" do
      process_monitor.static_context = { 'region' => 'west' }

      result = process_monitor.statically_targeted_settings
      result2 = process_monitor.statically_targeted_settings
      expect(result2.object_id).to eq(result.object_id)

      process_monitor.static_context = { 'region' => 'west' }

      result3 = process_monitor.statically_targeted_settings
      expect(result3.object_id).to_not eq(result.object_id)

      settings = result3.map { |s| s.process_settings.json_doc }
      expect(settings).to eq([{ 'sip' => true }, {"reject_call" => false}])
    end
  end

  describe "#targeted_value" do
    let(:process_monitor) { described_class.new(SETTINGS_PATH) }

    before do
      File.write(SETTINGS_PATH, EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "should respect static targeting with dynamic ovrrides" do
      process_monitor.static_context = { 'region' => 'east' }
      expect(process_monitor.targeted_value('sip', {})).to eq(true)
      expect(process_monitor.targeted_value('reject_call', {})).to eq(true)
      expect(process_monitor.targeted_value('reject_call', { 'caller_id' => '+18003334444' })).to eq(false)
      expect(process_monitor.targeted_value('reject_call', { 'caller_id' => '+18887776666' })).to eq(false)
      expect(process_monitor.targeted_value('reject_call', { 'caller_id' => '+12223334444' })).to eq(true)
    end
  end
end
