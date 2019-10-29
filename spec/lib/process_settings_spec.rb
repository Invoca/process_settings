# frozen_string_literal: true

require 'spec_helper'

describe ProcessSettings do
  describe 'Array Operator' do
    before do
      ProcessSettings::Monitor.file_path = "./spec/fixtures/production/combined_process_settings.yml"
      ProcessSettings::Monitor.logger = Logger.new(STDERR)
    end

    after do
      ProcessSettings::Monitor.file_path = nil
      ProcessSettings::Monitor.logger = nil
    end

    it 'delegates to the current monitor instance' do
      expect(ProcessSettings::Monitor.instance).to receive(:targeted_value).with('setting1', 'sub', 'enabled', dynamic_context: { "hello" => "world" }, required: true).and_return(true)
      expect(ProcessSettings['setting1', 'sub', 'enabled', dynamic_context: { "hello" => "world" }]).to eq(true)
    end

    it 'passes required: keyword arg' do
      expect(ProcessSettings::Monitor.instance).to receive(:targeted_value).with('setting1', dynamic_context: { "hello" => "world" }, required: false).and_return(true)
      expect(ProcessSettings['setting1', dynamic_context: { "hello" => "world" }, required: false]).to eq(true)
    end

    it 'defaults dynamic context to an empty hash' do
      expect(ProcessSettings::Monitor.instance).to receive(:targeted_value).with('setting1', 'enabled', dynamic_context: {}, required: true).and_return(true)
      expect(ProcessSettings['setting1', 'enabled']).to eq(true)
    end
  end
end
