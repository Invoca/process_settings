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

  let(:production_yaml) do
    <<~EOS
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
  end
  let(:output_file) { "tmp/output-#{Process.pid}.yml" }
  let(:command_options) { "--verbose" }
  let(:base_command) { "bin/combine_process_settings #{command_options}" }
  subject { `#{command}` }

  after { FileUtils.rm_f(output_file) }

  describe "when no arguments given" do
    let(:command) { "#{base_command} 2>&1" }

    it { should eq(help_text) }

    it 'exits with code 1' do
      subject
      expect($?.exitstatus).to eq(1)
    end
  end

  describe "when no -i and no --version are provided" do
    let(:command) { "#{base_command} -r spec/fixtures/production -o tmp/combined_process_settings.yml 2>&1" }

    it { should eq(help_text) }

    it 'exits with code 1' do
      subject
      expect($?.exitstatus).to eq(1)
    end
  end

  describe "when --version is provided" do
    let(:command) { "#{base_command} --version=42 -r spec/fixtures/production -o #{output_file} && cat #{output_file}" }

    it { should eq(<<~EOS + production_yaml) }
      spec/fixtures/production: UPDATING (unchanged now, but changed from initial)
    EOS

    it 'exits with code 0' do
      subject
      expect($?.exitstatus).to eq(0)
    end
  end

  describe "with initial combined_process_settings.yml" do
    let(:initial_file) { "tmp/initial-#{Process.pid}.yml" }
    let(:initial_settings_without_meta) { [] }
    let(:initial_settings_with_meta) { [*initial_settings_without_meta,
                                       { 'meta' => { 'version' => initial_file_version, 'END' => true } }] }
    let(:initial_file_version) { 42 }

    before { File.write(initial_file, initial_settings_with_meta.to_yaml) }
    after  { FileUtils.rm_f(initial_file) }

    describe "without --version provided" do
      let(:command) { "#{base_command} -r spec/fixtures/production -o #{output_file} -i #{initial_file} && cat #{output_file}" }

      describe 'the file version' do
        subject { YAML.load(`#{command}`.partition("\n").last).last.dig('meta', 'version') }

        it { should eq(initial_file_version + 1)}
      end

      it 'exits with code 0' do
        subject
        expect($?.exitstatus).to eq(0)
      end
    end

    describe "with --version provided" do
      let(:command) { "#{base_command} -r spec/fixtures/production -o #{output_file} --version=#{command_line_version} -i #{initial_file} && cat #{output_file}" }

      describe "version is set" do
        let(:command_line_version) { 98 }

        describe 'the file version' do
          subject { YAML.load(`#{command}`.partition("\n").last).last.dig('meta', 'version') }

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
          subject { YAML.load(`#{command}`.partition("\n").last).last.dig('meta', 'version') }

          it { should eq(initial_file_version + 1)}
        end

        it 'exits with code 0' do
          subject
          expect($?.exitstatus).to eq(0)
        end
      end

      describe "when version bumps" do
        describe "but no settings change between initial and current and next" do
          let(:command_line_version) { "1000" }
          let(:initial_settings_yaml) { production_yaml }

          before do
            before_output = `#{command.sub("1000", "999")}`
            @combined_before = before_output.partition("\n").last
            File.write(output_file, @combined_before)
            File.write(initial_file, initial_settings_yaml)
          end

          it 'leaves the output file unchanged' do
            output = subject
            expect(output).to eq("spec/fixtures/production: unchanged\n" + @combined_before)
          end

          it 'exits with code 0' do
            subject
            expect($?.exitstatus).to eq(0)
          end

          describe "but settings change from initial to current" do
            before do
              output = `#{command.sub(command_line_version, (command_line_version.to_i - 1).to_s)}`
              @combined_before = output.partition("\n").last
              File.write(initial_file, initial_settings_yaml.sub('region: east', 'region: west'))
            end

            it 'updates the output file with a new version' do
              output = subject
              expect(output).to eq("spec/fixtures/production: UPDATING (unchanged now, but changed from initial)\n" +
                                     @combined_before.sub("999", command_line_version))
            end

            it 'exits with code 0' do
              subject
              expect($?.exitstatus).to eq(0)
            end
          end

          describe "but settings change from current to next" do
            before do
              File.write(output_file, initial_settings_yaml.sub('region: east', 'region: west'))
            end

            it 'updates the output file with a new version' do
              output = subject
              expect(output).to eq("spec/fixtures/production: UPDATING (changed now)\n" + @combined_before.gsub("999", "1000"))
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
end
