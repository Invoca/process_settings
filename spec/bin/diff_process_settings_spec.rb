# frozen_string_literal: true

require 'spec_helper'

describe 'diff_process_settings' do
  it "ignores version number but sees other diffs" do
    output = `bin/diff_process_settings spec/fixtures/production/combined_process_settings-16.yml spec/fixtures/production/combined_process_settings.yml`
    expect(output).to eq(<<~EOS)
*** 5,11 ****
  - filename: honeypot.yml
    settings:
      honeypot:
!       max_recording_seconds: 300
        answer_odds: 100
        status_change_min_days: 10
  - filename: telecom/log_level.yml
--- 5,11 ----
  - filename: honeypot.yml
    settings:
      honeypot:
!       max_recording_seconds: 600
        answer_odds: 100
        status_change_min_days: 10
  - filename: telecom/log_level.yml
    EOS
  end

  it "ignores version number when there are no other diffs" do
    output = `bin/diff_process_settings spec/fixtures/production/combined_process_settings.yml spec/fixtures/production/combined_process_settings-18.yml`
    expect(output).to eq('')
  end

  it "sees no diffs on identical file" do
    output = `bin/diff_process_settings spec/fixtures/production/combined_process_settings.yml spec/fixtures/production/combined_process_settings.yml`
    expect(output).to eq('')
  end

  it "allows - meaning stdin" do
    output = `cat spec/fixtures/production/combined_process_settings-16.yml | bin/diff_process_settings - spec/fixtures/production/combined_process_settings.yml`
    expect(output).to eq(<<~EOS)
      *** 5,11 ****
        - filename: honeypot.yml
          settings:
            honeypot:
      !       max_recording_seconds: 300
              answer_odds: 100
              status_change_min_days: 10
        - filename: telecom/log_level.yml
      --- 5,11 ----
        - filename: honeypot.yml
          settings:
            honeypot:
      !       max_recording_seconds: 600
              answer_odds: 100
              status_change_min_days: 10
        - filename: telecom/log_level.yml
    EOS
  end

  TRUTHY_EXIT_STATUS = 0

  describe "with --silent" do
    let(:file_1) { "spec/fixtures/production/combined_process_settings.yml" }
    let(:file_2) { "spec/fixtures/production/combined_process_settings.yml" }
    subject { `bin/diff_process_settings --silent #{file_1} #{file_2}` }
    let(:child_status) { $? }
    let(:child_exitstatus) { child_status.exitstatus }

    context "when same settings/same version" do
      it "has no output and is truthy" do
        expect(subject).to eq('')
        expect(child_exitstatus).to eq(TRUTHY_EXIT_STATUS)
      end
    end

    context "when same settings/different version" do
      let(:file_2) { "spec/fixtures/production/combined_process_settings-19.yml" }

      it "has no output and is truthy" do
        expect(subject).to eq('')
        expect(child_exitstatus).to eq(TRUTHY_EXIT_STATUS)
      end
    end

    context "when different content/same version" do
      let(:file_2) { "spec/fixtures/production/combined_process_settings-18b.yml" }

      it "has no output but is falsey" do
        expect(subject).to eq('')
        expect(child_exitstatus).to_not eq(TRUTHY_EXIT_STATUS)
      end
    end

    context "when different content/different version" do
      let(:file_2) { "spec/fixtures/production/combined_process_settings-16.yml" }

      it "has no output and is falsey" do
        expect(subject).to eq('')
        expect(child_exitstatus).to_not eq(TRUTHY_EXIT_STATUS)
      end
    end
  end
end
