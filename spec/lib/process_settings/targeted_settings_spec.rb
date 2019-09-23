# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'process_settings/targeted_settings'

describe ProcessSettings::TargetedSettings do
  TARGETED_SETTINGS = [{
    'filename' => 'honeypot.yml',
    'target' => true,
    'settings' => {
      'honeypot' => {
        'promo_number' => '+18005554321'
      }
    }
  },
  { 'END' => true }].freeze

  puts "\n\n\n=================\n#{TARGETED_SETTINGS.inspect}"

  describe ".from_array" do
    it "delegates" do
      target_and_settings = described_class.from_array(TARGETED_SETTINGS)

      target = target_and_settings.targeted_settings_array.first.target
      expect(target.json_doc).to eq(true)
      expect(target).to be_kind_of(ProcessSettings::Target)

      process_settings = target_and_settings.targeted_settings_array.first.process_settings
      expect(process_settings.json_doc).to eq('honeypot' => { 'promo_number' => '+18005554321' })
      expect(process_settings).to be_kind_of(ProcessSettings::Settings)
    end

    it "confirms end is at end" do
      expect do
        puts "\n\n***************\n#{TARGETED_SETTINGS.inspect}\n\n"
        described_class.from_array(TARGETED_SETTINGS.reverse)
      end.to raise_error(ArgumentError, /Got \{"filename"=>"honeypot.yml",/)
    end
  end

  describe "[]" do
    it "allows hash key access to settings" do
      target_and_settings = described_class.from_array(TARGETED_SETTINGS)

      result = target_and_settings.targeted_settings_array.first.process_settings['honeypot' => 'promo_number']

      expect(result).to eq('+18005554321')
    end
  end
end
