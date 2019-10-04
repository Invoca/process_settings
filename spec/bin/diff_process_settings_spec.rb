# frozen_string_literal: true

require 'spec_helper'

describe 'diff_process_settings' do
  it "ignores version number but sees other diffs" do
    output = `bin/diff_process_settings spec/fixtures/production/combined_process_settings-16.yml spec/fixtures/production/combined_process_settings.yml`
    expect(output).to eq(<<~EOS)
      8c8
      <       max_recording_seconds: 300
      ---
      >       max_recording_seconds: 600
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
      8c8
      <       max_recording_seconds: 300
      ---
      >       max_recording_seconds: 600
    EOS
  end
end
