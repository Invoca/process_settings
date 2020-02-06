# frozen_string_literal: true

require 'yaml'
require 'spec_helper'
require 'process_settings/testing/monitor_stub'

describe ProcessSettings::Testing::MonitorStub do
  SETTINGS_HASH = YAML.load(<<~EOS)
                    ---
                    honeypot:
                      max_recording_seconds: 300
                      answer_odds: 100
                      status_change_min_days: 10
                  EOS

  subject { ProcessSettings::Testing::MonitorStub.new(SETTINGS_HASH) }

  describe "#targeted_value" do
    it "returns values when found" do
      result = subject.targeted_value('honeypot', 'answer_odds', dynamic_context: {})
      expect(result).to eq(100)
    end

    it "returns nil when not found and required: false" do
      result = subject.targeted_value('honeypot', 'unknown', dynamic_context: {}, required: false)
      expect(result).to eq(nil)
    end

    it "raises exception when not found and explicit required: true" do
      expect { subject.targeted_value('honeypot', 'unknown', dynamic_context: {}, required: true) }.to raise_exception(ProcessSettings::SettingsPathNotFound)
    end

    it "raises exception when not found and default required: true" do
      expect { subject.targeted_value('honeypot', 'unknown', dynamic_context: {}) }.to raise_exception(ProcessSettings::SettingsPathNotFound)
    end
  end
end
