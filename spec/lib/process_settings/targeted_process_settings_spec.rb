# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'process_settings/targeted_process_settings'

describe ProcessSettings::TargetedProcessSettings do
  TARGET_AND_SETTINGS = {
    'target' => true,
    'settings' => {
      'honeypot' => {
        'promo_number' => '+18005554321'
      }
    }
  }.freeze

  describe "target and process_settings" do
    it "should delegate" do
      target_and_process_settings = described_class.from_json([TARGET_AND_SETTINGS])

      target = target_and_process_settings.targeted_settings_array.first.target
      expect(target.json_doc).to eq(true)
      expect(target).to be_kind_of(ProcessSettings::ProcessTarget)

      process_settings = target_and_process_settings.targeted_settings_array.first.process_settings
      expect(process_settings.json_doc).to eq('honeypot' => { 'promo_number' => '+18005554321' })
      expect(process_settings).to be_kind_of(ProcessSettings::ProcessSettings)
    end
  end

  it "should allow hash key access to settings" do
    target_and_process_settings = described_class.from_json([TARGET_AND_SETTINGS])

    result = target_and_process_settings.targeted_settings_array.first.process_settings['honeypot' => 'promo_number']

    expect(result).to eq('+18005554321')
  end
end
