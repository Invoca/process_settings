# frozen_string_literal: true

require 'process_settings/util'
require 'process_settings/targeted_settings'
require 'process_settings/settings'

describe ProcessSettings do
  TARGETED_SETTINGS = [{
                         'filename' => 'honeypot.yml',
                         'target' => true,
                         'settings' => {
                           'honeypot' => {
                             'promo_number' => '+18005554321'
                           }
                         }
                       }].freeze

  let(:target_and_settings) { ProcessSettings::TargetedSettings.from_array(TARGETED_SETTINGS) }

  describe "utility class methods" do
    describe "plain_hash" do
      describe "when not used" do
        it "reveals HashWithHashPath" do
          expect(target_and_settings.to_yaml).to eq(<<~EOS)
            ---
            - target: true
              settings: !ruby/hash:ProcessSettings::HashWithHashPath
                honeypot:
                  promo_number: "+18005554321"
          EOS
        end
      end

      it "converts objects with json_doc method" do
        expect(ProcessSettings.plain_hash(ProcessSettings::Settings.new(TARGETED_SETTINGS.first)).to_yaml).to eq(<<~EOS)
          ---
          filename: honeypot.yml
          target: true
          settings:
            honeypot:
              promo_number: "+18005554321"
        EOS
      end

      it "converts arrays" do
        expect(ProcessSettings.plain_hash(TARGETED_SETTINGS).to_yaml).to eq(<<~EOS)
          ---
          - filename: honeypot.yml
            target: true
            settings:
              honeypot:
                promo_number: "+18005554321"
        EOS
      end
    end
  end
end
