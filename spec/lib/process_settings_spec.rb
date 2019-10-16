# frozen_string_literal: true

require 'spec_helper'
require 'process_settings'

describe ProcessSettings do
  describe 'Array Operator' do
    it 'delegates to the current monitor instance' do
      ProcessSettings::Monitor.file_path = "./spec/fixtures/production/combined_process_settings.yml"
      expect(ProcessSettings::Monitor.instance).to receive(:targeted_value).with('setting1', {}).and_return(true)
      expect(ProcessSettings['setting1', {}]).to eq(true)
    end
  end
end
