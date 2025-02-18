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
    'meta' => {
      'version' => 17,
      'END' => true
    }
  }].freeze

  describe "#initialize" do
    it "requires version:" do
      expected_message = if RUBY_VERSION < '2.7'
        /missing keyword: version/
      else
        /missing keyword: :version/
      end
      expect do
        described_class.new([])
      end.to raise_error(ArgumentError, expected_message)
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

      result = target_and_settings.targeted_settings_array.first.settings.json_doc.mine('honeypot', 'promo_number')

      expect(result).to eq('+18005554321')
    end
  end

  context "with file in tmp" do
    let(:tmp_file_path) { Tempfile.new(['combined_process_settings', '.yml'], File.expand_path('../../../tmp', __dir__)).path }

    before do
      File.write(tmp_file_path, TARGETED_SETTINGS.to_yaml)
    end

    after do
      FileUtils.rm_f(tmp_file_path)
    end

    describe ".from_file" do
      it "reads from yaml file" do
        targeted_settings = described_class.from_file(tmp_file_path)

        expect(targeted_settings.targeted_settings_array.size).to eq(1)
        expect(targeted_settings.targeted_settings_array.first.settings.json_doc.keys.first).to eq('honeypot')
        expect(targeted_settings.version).to eq(17)
      end

      it "infers version from END" do
        targeted_settings = described_class.from_file(tmp_file_path)
        expect(targeted_settings.targeted_settings_array.size).to eq(1)
        expect(targeted_settings.version).to eq(17)
      end

      it "infers version from END faster with only_meta: true" do
        targeted_settings = described_class.from_file(tmp_file_path, only_meta: true)
        expect(targeted_settings.targeted_settings_array.size).to eq(0)
        expect(targeted_settings.version).to eq(17)
      end
    end
  end

  describe ".from_array" do
    it "delegates" do
      target_and_settings = described_class.from_array(TARGETED_SETTINGS)

      target = target_and_settings.targeted_settings_array.first.target
      expect(target.json_doc).to eq(true)
      expect(target).to be_kind_of(ProcessSettings::Target)

      settings = target_and_settings.targeted_settings_array.first.settings
      expect(settings.json_doc).to eq('honeypot' => { 'promo_number' => '+18005554321' })
      expect(settings).to be_kind_of(ProcessSettings::Settings)
    end

    it "confirms meta: is at end" do
      expect do
        described_class.from_array(TARGETED_SETTINGS.reverse)
      end.to raise_error(ArgumentError, /got \{"filename"\s*=>\s*"honeypot.yml",/)
    end

    it "requires meta: at end" do
      expect do
        described_class.from_array(TARGETED_SETTINGS[0, 1])
      end.to raise_error(ArgumentError, /Missing meta:/)
    end

    it "requires END: true at end of meta: section" do
      expect do
        described_class.from_array(TARGETED_SETTINGS[0, 1] + [ { 'meta' => { 'END' => true, 'version' => 42 } }])
      end.to raise_error(ArgumentError, /END: true must be at end of file/)
    end

    it "infers version from meta" do
      targeted_settings = described_class.from_array(TARGETED_SETTINGS)
      expect(targeted_settings.targeted_settings_array.size).to eq(1)
      expect(targeted_settings.version).to eq(17)
    end

    it "infers version from meta faster with only_meta: true" do
      targeted_settings = described_class.from_array(TARGETED_SETTINGS, only_meta: true)
      expect(targeted_settings.targeted_settings_array.size).to eq(0)
      expect(targeted_settings.version).to eq(17)
    end
  end
end
