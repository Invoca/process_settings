# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'process_settings/settings'

describe ProcessSettings::Settings do
  describe "initialize" do
    it "should take a json doc" do
      process_settings = described_class.new("carrier" => "AT&T")

      expect(process_settings["carrier"]).to eq("AT&T")
    end

    it "should reject anything not a hash" do
      expect do
        described_class.new("{}")
      end.to raise_exception(ArgumentError, /Settings must be a Hash/)
    end
  end

  describe "#json_doc" do
    it "should return what was stored" do
      process_settings = described_class.new("carrier" => "AT&T")

      expect(process_settings.json_doc).to eq("carrier" => "AT&T")
    end
  end
end
