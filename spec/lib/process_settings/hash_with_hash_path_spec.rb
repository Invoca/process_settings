# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/hash_with_hash_path'

describe ProcessSettings::HashWithHashPath do
  describe "#initialize" do
    it "should default to an empty hash" do
      hash = described_class.new

      expect(hash).to eq({})
      expect(hash).to be_kind_of(described_class)
    end
  end

  describe ".[]" do
    it "should copy from a regular hash" do
      hash = described_class[address: { city: "Santa Barbara" }]

      expect(hash).to eq(address: { city: "Santa Barbara" })
      expect(hash).to be_kind_of(described_class)

      sub_hash = hash[:address]
      expect(sub_hash).to eq(city: "Santa Barbara")
      expect(sub_hash).to_not be_kind_of(described_class)
      expect(sub_hash).to be_kind_of(Hash)
    end
  end

  describe "#[]" do
    it "should support hash keys" do
      hash = described_class[address: { city: "Santa Barbara" }]

      result = hash[address: :city]
      expect(result).to eq("Santa Barbara")
    end
  end
end
