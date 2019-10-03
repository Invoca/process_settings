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
  }, {
    'END' => {
      'version' => 17.9
    }
  }].freeze

  describe "#initialize" do
    it "requires version:" do
      expect do
        described_class.new([])
      end.to raise_error(ArgumentError, /missing keyword: version/)
    end

    it "requires non-empty version:" do
      expect do
        described_class.new([], version: nil)
      end.to raise_error(ArgumentError, /version must not be empty/)
    end
  end

  describe "[]" do
    it "allows hash key access to settings" do
      target_and_settings = described_class.from_array(TARGETED_SETTINGS)

      result = target_and_settings.targeted_settings_array.first.process_settings['honeypot' => 'promo_number']

      expect(result).to eq('+18005554321')
    end
  end

  TMP_FILE_PATH = "tmp/test_process_settings.yml"

  context "with file in tmp" do
    before do
      File.write(TMP_FILE_PATH, TARGETED_SETTINGS.to_yaml)
    end

    after do
      FileUtils.rm_f(TMP_FILE_PATH)
    end

    describe ".from_file" do
      it "reads from yaml file" do
        targeted_settings = described_class.from_file(TMP_FILE_PATH)

        expect(targeted_settings.targeted_settings_array.size).to eq(1)
        expect(targeted_settings.targeted_settings_array.first.process_settings.json_doc.keys.first).to eq('honeypot')
        expect(targeted_settings.version).to eq(17.9)
      end
    end
  end

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

    it "confirms END is at end" do
      expect do
        described_class.from_array(TARGETED_SETTINGS.reverse)
      end.to raise_error(ArgumentError, /Got \{"filename"=>"honeypot.yml",/)
    end

    it "requires END at end" do
      expect do
        described_class.from_array(TARGETED_SETTINGS[0, 1])
      end.to raise_error(ArgumentError, /Missing END/)
    end

    it "infers version from END" do
      targeted_settings = described_class.from_array(TARGETED_SETTINGS)
      expect(targeted_settings.version).to eq(17.9)
    end

    it "treats old END: true format as { 'version' => 0 }" do
      targeted_settings = described_class.from_array([{ 'END' => true }])
      expect(targeted_settings.version).to eq(0.0)
    end
  end
end
