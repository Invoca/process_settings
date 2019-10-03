# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/hash_path'

describe 'combine_process_settings' do
  it "should print usage and exit 1 if no arguments given" do
    output = `bin/combine_process_settings 2>&1`

    expect(output).to eq(<<~EOS)
      usage: combine_process_settings -r staging|production -o combined_process_settings.yml [-i initial_combined_process_settings.yml] (required if BUILD_NUMBER not set)
          -v, --verbose                    Verbose mode.
          -r, --root_folder=ROOT
          -o, --output=FILENAME            Output file.
          -i, --initial=FILENAME           Initial settings file for version inference.
    EOS
    expect($?.exitstatus).to eq(1)
  end

  it "should print usage and exit 1 if no -i and no BUILD_NUMBER set" do
    output = `bin/combine_process_settings -r spec/fixtures/production -o tmp/combined_process_settings.yml 2>&1`

    expect(output).to eq(<<~EOS)
      usage: combine_process_settings -r staging|production -o combined_process_settings.yml [-i initial_combined_process_settings.yml] (required if BUILD_NUMBER not set)
          -v, --verbose                    Verbose mode.
          -r, --root_folder=ROOT
          -o, --output=FILENAME            Output file.
          -i, --initial=FILENAME           Initial settings file for version inference.
    EOS
    expect($?.exitstatus).to eq(1)
  end

  it "should combine all settings files alphabetically, with a magic comment at the top and END: at the end" do
    output = `BUILD_NUMBER=42 bin/combine_process_settings -r spec/fixtures/production -o tmp/combined_process_settings.yml && cat tmp/combined_process_settings.yml && rm -f tmp/combined_process_settings.yml`

    expect(output).to eq(<<~EOS)
      ---
      #
      # Don't edit this file directly! It was generated by combine_process_settings from the files in production/settings/.
      #
      - filename: debug_sip_private_caller_id.yml
        target:
          app: ringswitch
          region: west
        settings:
          log_stream:
            sip: caller_id_privacy
      - filename: flag_drop.yml
        target:
          region: east
        settings:
          reject_incoming_calls: 0
      - filename: honeypot.yml
        settings:
          honeypot:
            max_recording_seconds: 600
            answer_odds: 100
            status_change_min_days: 10
      - filename: tech-1234_call_counts_drift_investigation.yml
        target:
          app: ccn
        settings:
          call_counts:
            complete_sync_seconds: 60
      - END:
          version: 42.0
    EOS

    expect($?.exitstatus).to eq(0)
  end

  context "with initial combined_process_settings.yml" do
    before do
      FileUtils.mkdir("tmp") rescue nil
      File.write("tmp/combined_process_settings.yml", [{ 'END' => { 'version' => 42.0 } }].to_yaml)
    end

    after do
      FileUtils.rm_f("tmp/combined_process_settings.yml")
    end

    it "use a default END: version of the old version with timestamp beyond decimal place" do
      time_t = Time.now.to_i

      output = `bin/combine_process_settings -r spec/fixtures/production -o tmp/combined_process_settings.yml -i tmp/combined_process_settings.yml && cat tmp/combined_process_settings.yml`
      expect($?.exitstatus).to eq(0), output

      output_json_doc = YAML.load(output)

      version = output_json_doc.last['END']&.[]('version')

      major, minor = version.divmod(1)

      expect(major).to eq(42), version.to_s
      expect(minor * 10_000_000_000).to be_between(time_t, time_t + 10), version.to_s
    end
  end
end
