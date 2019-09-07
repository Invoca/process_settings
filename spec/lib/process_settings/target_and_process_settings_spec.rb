# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/target_and_process_settings'

describe ProcessSettings::TargetAndProcessSettings do
  describe "#target" do
    it "should return target passed to #initialize" do
      expect(sample_target_and_process_settings.target).to eq(sample_target)
    end
  end

  describe "#process_settings" do
    it "should return process_settings passed to #initialize" do
      expect(sample_target_and_process_settings.process_settings).to eq(sample_process_settings)
    end
  end

  describe ".from_json" do
    it "should parse json pair" do
      target_json_doc = { 'region' => 'east' }
      target_settings_json_doc = { 'sip' => true }
      target_and_process_settings = described_class.from_json_docs(target_json_doc, target_settings_json_doc)

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

  private

  def sample_target
    @sample_target ||= ProcessSettings::ProcessTarget.new('region' => 'east')
  end

  def sample_process_settings
    @sample_process_settings ||= ProcessSettings::ProcessSettings.new("carrier" => "AT&T")
  end

  def sample_target_and_process_settings
    @sample_target_and_process_settings ||= begin
      described_class.new(sample_target, sample_process_settings)
    end
  end
end
