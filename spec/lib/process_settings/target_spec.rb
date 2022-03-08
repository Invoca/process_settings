# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require_relative '../../../lib/process_settings/target'

describe ProcessSettings::Target do
  describe "#process_target" do
    it "should return what was constructed with" do
      process_target = described_class.new(true)
      expect(process_target.json_doc).to eq(true)

      process_target = described_class.new('sip_enabled' => true)
      expect(process_target.json_doc).to eq('sip_enabled' => true)
    end
  end

  describe "#target_key_matches?" do
    it "should always match true" do
      context_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }

      process_target = described_class.new(true)

      expect(process_target.target_key_matches?(context_hash)).to eq(true)
    end

    it "should never match false" do
      context_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }

      process_target = described_class.new(false)

      expect(process_target.target_key_matches?(context_hash)).to eq(false)
    end

    it "should match a single value" do
      context_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      target_hash = {
        'service' => 'telecom'
      }

      process_target = described_class.new(target_hash)

      expect(process_target.target_key_matches?(context_hash)).to be_truthy
      expect(process_target.target_key_matches?({})).to be_falsey
    end

    it "should match a single value on truthiness" do
      context_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'sip_enabled' => 'yes'
      }
      target_hash = {
        'sip_enabled' => true
      }

      process_target = described_class.new(target_hash)

      expect(process_target.target_key_matches?(context_hash)).to be_truthy
      expect(process_target.target_key_matches?({})).to be_falsey
    end

    it "should match a single value on falsiness/missing" do
      context_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'sip_enabled' => 'yes'
      }
      target_hash = {
        'sip_disabled' => false
      }

      process_target = described_class.new(target_hash)

      expect(process_target.target_key_matches?(context_hash)).to be_falsey
    end

    it "should match an array of values" do
      context_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      target_hash = {
        'service' => ['telecom', 'pnapi']
      }

      process_target = described_class.new(target_hash)

      expect(process_target.target_key_matches?(context_hash)).to be_truthy
      expect(process_target.target_key_matches?({})).to be_falsey
    end

    it "should match an array of values" do
      context_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      target_hash = {
        'service' => ['telecom', 'pnapi']
      }

      process_target = described_class.new(target_hash)

      expect(process_target.target_key_matches?(context_hash)).to be_truthy
      expect(process_target.target_key_matches?({})).to be_falsey
    end

    it "should match an array of values on truthiness" do
      context_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'sip_enabled' => 'yes'
      }
      target_hash = {
        'sip_enabled' => ['true', true]
      }

      process_target = described_class.new(target_hash)

      expect(process_target.target_key_matches?(context_hash)).to be_truthy
      expect(process_target.target_key_matches?({})).to be_falsey
    end

    describe "for regex matching" do
      subject { process_target.target_key_matches?(context_hash) }
      let(:process_target) { described_class.new(target_hash) }
      let(:context_hash) do
        {
          'service' => service,
          'region'  => 'east',
          'cdr'     => { 'caller' => '+18056807000' }
        }
      end

      context "with target value that has a slash at the start and end" do
        let(:target_hash) { { 'service' => '/telecom/' } }

        context "when context hash value matches" do
          let(:service) { 'telecom-1' }

          it { is_expected.to be_truthy }
        end

        context "with an empty context hash" do
          let(:context_hash) { {} }
          it { is_expected.to be_falsey }
        end

        context "with a non-matching context value" do
          let(:service) { 'tele' }
          it { is_expected.to be_falsey }
        end
      end

      context "when target value only has a leading slash" do
        let(:target_hash) { { 'service' => '/telecom' } }

        context "when context hash value has the string but not the slash" do
          let(:service) { 'telecom' }

          it { is_expected.to be_falsey }
        end

        context "when context hash value exactly matches target value" do
          let(:service) { '/telecom' }
          it { is_expected.to be_truthy }
        end
      end

      context "when target value only has a trailing slash" do
        let(:target_hash) { { 'service' => 'telecom/' } }

        context "when context hash value has the string but not the slash" do
          let(:service) { 'telecom' }

          it { is_expected.to be_falsey }
        end

        context "when context hash value exactly matches target value" do
          let(:service) { 'telecom/' }
          it { is_expected.to be_truthy }
        end
      end

      context "when target value has embedded slashes (not at the front or back)" do
        let(:target_hash) { { 'service' => 'tmp/dir/log' } }

        context "when context hash value is the target value except the first and last character" do
          let(:service) { 'mp/dir/lo' }
          it { is_expected.to be_falsey }
        end

        context "when context hash value exactly matches target value" do
          let(:service) { 'tmp/dir/log' }
          it { is_expected.to be_truthy }
        end
      end

      context "when target value is valid and also has embedded slashes" do
        let(:target_hash) { { 'service' => '/tmp/dir/log/'} }

        context "when context hash value matches the target" do
          let(:service) { 'tmp/dir/log/service-log.txt' }
          it { is_expected.to be_truthy }
        end

        context "when context hash only has whats between the embedded slashes" do
          let(:service) { 'dir' }
          it { is_expected.to be_falsey }
        end
      end

      context "when target value is two slashes and nothing else" do
        let(:target_hash) { { 'service' => '//' } }
        context "when context hash value exactly matches" do
          let(:service) {'//' }
          it { is_expected.to be_truthy }
        end

        context "when context hash value is empty" do
          let(:service) {'' }
          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe "#with_static_context" do
    it "should remove a truthy hash key" do
      target_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      context_hash = {
        'service' => 'telecom'
      }

      process_target = described_class.new(target_hash)

      result = process_target.with_static_context(context_hash)

      expect(result.json_doc).to eq('region' => 'east', 'cdr' => { 'caller' => '+18056807000' })
    end

    it "should replace a hash with all truthy keys with true" do
      target_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      context_hash = target_hash

      process_target = described_class.new(target_hash)

      result = process_target.with_static_context(context_hash)

      expect(result.json_doc).to eq(true)
    end

    it "should remove a truthy hash key (matched on a falsey value)" do
      target_hash = {
        'using_sip' => false,
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      context_hash = {
        'using_sip' => false
      }

      process_target = described_class.new(target_hash)

      result = process_target.with_static_context(context_hash)

      expect(result.json_doc).to eq('region' => 'east', 'cdr' => { 'caller' => '+18056807000' })
    end

    it "should remove a truthy hash key in an array" do
      target_hash = {
        'service' => ['telecom', 'pnapi'],
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      context_hash = {
        'service' => 'telecom'
      }

      process_target = described_class.new(target_hash)

      result = process_target.with_static_context(context_hash)

      expect(result.json_doc).to eq('region' => 'east', 'cdr' => { 'caller' => '+18056807000' })
    end

    [false, nil].each do |falsey_value|
      it "should remove a truthy hash key in an array (where match is on a falsey value (#{falsey_value.inspect})" do
        target_hash = {
          'using_sip' => [false, nil],
          'region' => ['east', 'west'],
          'cdr' => { 'caller' => '+18056807000' }
        }
        context_hash = {
          'using_sip' => falsey_value
        }

        process_target = described_class.new(target_hash)

        result = process_target.with_static_context(context_hash)

        expect(result.json_doc).to eq('region' => ['east', 'west'], 'cdr' => { 'caller' => '+18056807000' })
      end
    end

    it "should short-circuit hash as false if falsey hash key" do
      target_hash = {
        'service' => 'telecom',
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      context_hash = {
        'service' => 'pnapi'
      }

      process_target = described_class.new(target_hash)

      result = process_target.with_static_context(context_hash)

      expect(result.json_doc).to eq(false)
    end

    it "should short-circuit hash as false if falsey hash key is an array" do
      target_hash = {
        'service' => ['telecom', 'fe'],
        'region' => 'east',
        'cdr' => { 'caller' => '+18056807000' }
      }
      context_hash = {
        'service' => 'pnapi'
      }

      process_target = described_class.new(target_hash)

      result = process_target.with_static_context(context_hash)

      expect(result.json_doc).to eq(false)
    end

    describe "when target hash has nested values" do
      subject { described_class.new(target_hash).with_static_context(context_hash).json_doc }

      describe "when the context contains the nested structure of the target hash" do
        let(:target_hash) do
          {
            'services' => {
              'region' => 'west'
            }
          }
        end

        describe "when the target matches the context" do
          let(:context_hash) do
            {
              'services' => {
                'region' => 'west'
              }
            }
          end

          it { should eq(true) }
        end

        describe "when the target does not match the context" do
          let(:context_hash) {
            {
              'services' => {
                'region' => 'east'
              }
            }
          }

          it { should eq(false)}
        end
      end

      describe "when the context contains only the first level of the target hash" do
        let(:target_hash) do
          {
            'services' => {
              'something_else' => 'blue'
            }
          }
        end

        let(:context_hash) do
          {
            'services' => {
              'region' => 'west'
            }
          }
        end

        it { should eq(false)}
      end

      describe "when the context contains none of the target hash" do
        let(:target_hash) do
          {
            'something_else' => {
              'region' => 'west'
            }
          }
        end

        let(:context_hash) do
          {
            'services' => {
              'region' => 'west'
            }
          }
        end

        it { should eq(target_hash) }
      end
    end
  end

  describe "class methods" do
    describe "true_target" do
      subject { described_class.true_target.json_doc }
      it { should eq({}) }
    end
  end
end
