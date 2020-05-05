# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'process_settings/settings'

describe ProcessSettings::Settings do
  let(:settings_json_doc) { { "log_level" => "debug" } }
  subject { described_class.new(settings_json_doc) }

  describe "#initialize" do
    context "with a non-hash argument" do
      let(:settings_json_doc) { "{}" }

      it "raises" do
        expect { subject }.to raise_exception(ArgumentError, /Settings must be a Hash/)
      end
    end

    context "with a symbol key" do
      let(:settings_json_doc) { { "gem" => { log_level: "debug" } } }

      it "raises" do
        expect { subject }.to raise_exception(ArgumentError, /symbol key :log_level found/)
      end
    end

    context "with a symbol value" do
      let(:settings_json_doc) { { "log_level" => :debug } }

      it "raises" do
        expect { subject }.to raise_exception(ArgumentError, /symbol value :debug found/)
      end
    end
  end

  describe "#json_doc" do
    it "returns what was stored" do
      expect(subject.json_doc).to eq(settings_json_doc)
    end
  end
end
