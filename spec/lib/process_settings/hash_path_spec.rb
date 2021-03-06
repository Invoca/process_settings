# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/hash_path'

describe ProcessSettings::HashPath do
  describe "when module prepended into Hash" do
    let(:symbol_hash) do
      @symbol_hash = { address: { city: "Santa Barbara", state: "CA" }, phone_number: "888-555-4321" }
      class << @symbol_hash
        prepend ProcessSettings::HashPath
      end
      @symbol_hash
    end

    let(:string_hash) do
      @string_hash = { "address" => { "city" => "Santa Barbara", "state" => "CA" }, "phone_number" => "888-555-4321" }
      class << @string_hash
        prepend ProcessSettings::HashPath
      end
      @string_hash
    end

    describe "#mine" do
      describe "simple key" do
        it "returns value when found" do
          result = symbol_hash.mine(:address)
          expect(result).to eq(city: "Santa Barbara", state: "CA")
          result = string_hash.mine("address")
          expect(result).to eq("city" => "Santa Barbara", "state" => "CA")
        end

        it "returns nil when not found" do
          result = symbol_hash.mine(:name)
          expect(result).to eq(nil)
          result = string_hash.mine("name")
          expect(result).to eq(nil)
        end

        it "returns optional not_found value when not found" do
          result = symbol_hash.mine(:name, not_found_value: :not_found)
          expect(result).to eq(:not_found)
          result = string_hash.mine("name", not_found_value: :not_found)
          expect(result).to eq(:not_found)
        end

        it "yields and returns that value when not found" do
          block_called = nil
          result = symbol_hash.mine(:name, not_found_value: :not_found_unused) { block_called = 0; :not_found }
          expect(result).to eq(:not_found)
          expect(block_called).to eq(0)
          result = string_hash.mine("name", not_found_value: :not_found_unused) { block_called = 1; :not_found}
          expect(result).to eq(:not_found)
          expect(block_called).to eq(1)
        end
      end

      describe "compound key" do
        it "returns value when found" do
          result = symbol_hash.mine(:address, :state)
          expect(result).to eq("CA")
          result = string_hash.mine("address", "state")
          expect(result).to eq("CA")
        end

        it "nil when not found" do
          result = symbol_hash.mine(:name, :first)
          expect(result).to eq(nil)
          result = string_hash.mine("name", "first")
          expect(result).to eq(nil)
        end
      end
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
        result = described_class.hash_at_path({ key: [:value0, :value1, :value2] }, key: 2)
        expect(result).to eq(:value2)

        result = described_class.hash_at_path({ key: [:value0, :value1, :value2] }, key: 2)
        expect(result).to eq(:value2)
      end

      it "should raise an exception with multiple keys in the path" do
        expect do
          described_class.hash_at_path({ key: :value }, key0: 0, key1: 1)
        end.to raise_exception(ArgumentError, /path may have at most 1 key/)
      end
    end
  end
end
