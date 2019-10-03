# frozen_string_literal: true

require 'spec_helper'
require 'process_settings/hash_path'

describe 'process_settings_version' do
  it "returns the version on its own line on STDOUT" do
    output = `./bin/process_settings_version spec/fixtures/production/combined_process_settings.yml`

    expect(output).to eq("17.9\n")
  end
end
