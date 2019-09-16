# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/target_and_process_settings'

describe ProcessSettings::TargetAndProcessSettings do
  describe "#initialize" do
    it "should store args passed in" do
      sample = sample_target_and_process_settings
      expect(sample.filename).to eq("settings.yml")
      expect(sample.target).to eq(sample_target)
      expect(sample.process_settings).to eq(sample_process_settings)
    end
  end

  describe "#process_settings" do
    it "should return process_settings passed to #initialize" do
      expect(sample_target_and_process_settings.process_settings).to eq(sample_process_settings)
    end
  end

  describe ".from_json_docs" do
    it "should parse json pair" do
      target_json_doc = { 'region' => 'east' }
      target_settings_json_doc = { 'sip' => true }
      target_and_process_settings = described_class.from_json_docs("sip.yml", target_json_doc, target_settings_json_doc)

      expect(target_and_process_settings.target.json_doc).to eq(target_json_doc)
      expect(target_and_process_settings.process_settings.json_doc).to eq(target_settings_json_doc)
    end
  end

  describe "with_static_context" do
    it "should return a copy of self with static context applied" do
      initial_value = sample_target_and_process_settings

      with_static_context = initial_value.with_static_context('region' => 'west')

      expect(initial_value).to_not eq(with_static_context)
    end

    it "should return self when static context leaves it unchanged" do
      initial_value = sample_target_and_process_settings

      with_static_context = initial_value.with_static_context('service' => 'ringswitch')

      expect(initial_value.object_id).to eq(with_static_context.object_id)
    end
  end

  describe "#== and .eql?" do
    it "is equal when dup'd" do
      initial_value = sample_target_and_process_settings
      dup_value = initial_value.dup

      expect(initial_value).to eq(dup_value)
      expect(initial_value.eql?(dup_value)).to be_truthy
    end

    it "is equal even if filename is different" do
      initial_value = sample_target_and_process_settings
      dup_value = described_class.new("different_filename.yml", initial_value.target, initial_value.process_settings)

      expect(initial_value).to eq(dup_value)
      expect(initial_value.eql?(dup_value)).to be_truthy
    end

    it "is unequal if target is different" do
      initial_value = sample_target_and_process_settings
      new_value = described_class.new(initial_value.filename, ProcessSettings::ProcessTarget.new('region' => 'west'), initial_value.process_settings)

      expect(initial_value).to_not eq(new_value)
      expect(initial_value.eql?(new_value)).to be_falsey
    end

    it "is unequal if process settings are different" do
      initial_value = sample_target_and_process_settings
      dup_value = described_class.new(initial_value.filename, initial_value.target, ProcessSettings::ProcessSettings.new("carrier" => "O2"))

      expect(initial_value).to_not eq(dup_value)
      expect(initial_value.eql?(dup_value)).to be_falsey
    end
  end

  private

  def sample_target
    @sample_target ||= ProcessSettings::ProcessTarget.new('region' => 'east')
  end

  def sample_process_settings
    @sample_process_settings ||= ProcessSettings::ProcessSettings.new("carrier" => "AT&T")
  end

  def sample_target_and_process_settings
    @sample_target_and_process_settings ||= begin
      described_class.new("settings.yml", sample_target, sample_process_settings)
    end
  end
end
