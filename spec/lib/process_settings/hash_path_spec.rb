# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/hash_path'

describe ProcessSettings::HashPath do
  describe "when module prepended into Hash" do
    before do
      @symbol_hash = { address: { city: "Santa Barbara", state: "CA" }, phone_number: "888-555-4321" }
      @string_hash = { "address" => { "city" => "Santa Barbara", "state" => "CA" }, "phone_number" => "888-555-4321" }
      class << @symbol_hash
        prepend ProcessSettings::HashPath
      end
      class << @string_hash
        prepend ProcessSettings::HashPath
      end
    end

    it "should override [] for hash key" do
      result = @symbol_hash[address: :state]
      expect(result).to eq("CA")
      result = @string_hash["address" => "state"]
      expect(result).to eq("CA")
    end

    it "should pass through [] for simple key" do
      result = @symbol_hash[:address]
      expect(result).to eq(city: "Santa Barbara", state: "CA")
      result = @string_hash["address"]
      expect(result).to eq("city" => "Santa Barbara", "state" => "CA")
    end
  end

  describe "module methods" do
    describe ".hash_at_path" do
      it "should return the hash when path is empty" do
        result = described_class.hash_at_path({ key: :value }, {})
        expect(result).to eq(key: :value)

        result = described_class.hash_at_path({ "key" => "value" }, {})
        expect(result).to eq("key" => "value")
      end

      it "should return a simple value at a key" do
        result = described_class.hash_at_path({ key: :value }, :key)
        expect(result).to eq(:value)

        result = described_class.hash_at_path({ "key" => "value" }, "key")
        expect(result).to eq("value")
      end

      it "should return a nested value at a key" do
        result = described_class.hash_at_path({ key: { subkey: :value } }, :key)
        expect(result).to eq(subkey: :value)

        result = described_class.hash_at_path({ "key" => { "subkey" => "value" } }, "key")
        expect(result).to eq("subkey" => "value")
      end

      it "should return an array index value" do
        result = described_class.hash_at_path([:value0, :value1, :value2], 2)
        expect(result).to eq(:value2)
      end

      it "should return an array index value at a key" do
        result = described_class.hash_at_path({ key: [:value0, :value1, :value2] }, { key: 2 })
        expect(result).to eq(:value2)

        result = described_class.hash_at_path({ key: [:value0, :value1, :value2] }, { key: 2 })
        expect(result).to eq(:value2)
      end

      it "should raise an exception with multiple keys in the path" do
        expect do
          described_class.hash_at_path({ key: :value }, { key0: 0, key1: 1 })
        end.to raise_exception(ArgumentError, /path may have at most 1 key/)
      end
    end

    describe "set_hash_at_path" do
      it "should set a new key" do
        result = described_class.set_hash_at_path({ key: :value }, {})
        expect(result).to eq(key: :value)

        result = described_class.set_hash_at_path({ "key" => "value" }, {})
        expect(result).to eq("key" => "value")
      end

      it "should set a new key 2 levels down" do
        result = described_class.set_hash_at_path({ key: { subkey: :value } }, {})
        expect(result).to eq(key: { subkey: :value } )

        result = described_class.set_hash_at_path({ "key" => { "subkey" => "value" } }, {})
        expect(result).to eq("key" => { "subkey" => "value" })
      end

      it "should merge a new key" do
        result = described_class.set_hash_at_path({ key: :value }, { other_key: :other_value })
        expect(result).to eq(key: :value, other_key: :other_value)

        result = described_class.set_hash_at_path({ "key" => "value" }, { "other_key" => "other_value" })
        expect(result).to eq("key" => "value", "other_key" => "other_value" )
      end

      it "should raise an exception if not a hash" do
        expect do
          described_class.set_hash_at_path({ key: :value }, true)
        end.to raise_exception(ArgumentError, /got unexpected non-hash value/)
      end
    end
  end
end
