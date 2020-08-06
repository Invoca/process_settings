# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/hash_path'

describe 'combine_process_settings' do
  let(:help_text) { <<~EOS }
    usage: combine_process_settings -r staging|production -o combined_process_settings.yml [--version=VERSION] [-i initial_combined_process_settings.yml] (-i required if --version= not set)
        -v, --verbose                    Verbose mode.
        -n, --version=VERSION            Set version number.
        -r, --root_folder=ROOT
        -o, --output=FILENAME            Output file.
        -i, --initial=FILENAME           Initial settings file for version inference.
  EOS

  let(:tmp_file) { Tempfile.new(['combined_process_settings', '.yml'], 'tmp').path }

  subject { `#{command}`}

  after { FileUtils.rm_f(tmp_file) }

  describe "when no arguments given" do
    let(:command) { "bin/combine_process_settings 2>&1" }

    it { should eq(help_text) }

    it 'exits with code 1' do
      subject
      expect($?.exitstatus).to eq(1)
    end
  end

  describe "when no -i and no --version are provided" do
    let(:command) { "bin/combine_process_settings -r spec/fixtures/production -o tmp/combined_process_settings.yml 2>&1" }

    it { should eq(help_text) }

    it 'exits with code 1' do
      subject
      expect($?.exitstatus).to eq(1)
    end
  end

  describe "when --version is provided" do
    let(:command) { "bin/combine_process_settings --version=42 -r spec/fixtures/production -o #{tmp_file} && cat #{tmp_file}" }

    it { should eq(<<~EOS) }
      ---
      #
      # Don't edit this file directly! It was generated by combine_process_settings from the files in production/settings/.
      #
      - filename: debug_sip_private_caller_id.yml
        target:
          app: telecom
          region: west
        settings:
          log_stream:
            sip: caller_id_privacy
      - filename: honeypot.yml
        settings:
          honeypot:
            max_recording_seconds: 600
            answer_odds: 100
            status_change_min_days:
      - filename: stop_incoming_requests.yml
        target:
          region: east
        settings:
          incoming_requests: 0
      - filename: tech-1234_call_counts_drift_investigation.yml
        target:
          app: ccn
        settings:
          call_counts:
            complete_sync_seconds: 60
      - meta:
          version: 42
          END: true
    EOS

    it 'exits with code 0' do
      subject
      expect($?.exitstatus).to eq(0)
    end
  end

  describe "with initial combined_process_settings.yml" do
    let(:tmp_initial_file) { Tempfile.new(['prev_combined_process_settings', '.yml'], 'tmp').path }
    let(:initial_file_version) { 42 }

    before { File.write(tmp_initial_file, [{ 'meta' => { 'version' => initial_file_version, 'END' => true } }].to_yaml) }
    after  { FileUtils.rm_f(tmp_initial_file) }

    describe "without --version provided" do
      let(:command) { "bin/combine_process_settings -r spec/fixtures/production -o #{tmp_file} -i #{tmp_initial_file} && cat #{tmp_file}" }

      describe 'the file version' do
        subject { YAML.load(`#{command}`).last['meta']&.[]('version') }

        it { should eq(initial_file_version + 1)}
      end

      it 'exits with code 0' do
        subject
        expect($?.exitstatus).to eq(0)
      end
    end

    describe "with --version provided" do
      let(:command) { "bin/combine_process_settings -r spec/fixtures/production -o #{tmp_file} --version=#{command_line_version} -i #{tmp_initial_file} && cat #{tmp_file}" }

      describe "version is set" do
        let(:command_line_version) { 98 }

        describe 'the file version' do
          subject { YAML.load(`#{command}`).last['meta']&.[]('version') }

          it { should eq(command_line_version)}
        end

        it 'exits with code 0' do
          subject
          expect($?.exitstatus).to eq(0)
        end
      end

      describe "version is empty" do
        let(:command_line_version) { "" }

        describe 'the file version' do
          subject { YAML.load(`#{command}`).last['meta']&.[]('version') }

          it { should eq(initial_file_version + 1)}
        end

        it 'exits with code 0' do
          subject
          expect($?.exitstatus).to eq(0)
        end
      end

      describe "when version bumps" do
        describe "but no settings change" do
          let(:command_line_version) { "1000" }

          before do
            @combined_before = `#{command.sub("1000", "999")}`
          end

          it 'leaves the output file unchanged' do
            subject
            expect(File.read(tmp_file)).to eq(@combined_before)
          end

          it 'exits with code 0' do
            subject
            expect($?.exitstatus).to eq(0)
          end
        end
      end
    end
  end
end
