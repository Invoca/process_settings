# frozen_string_literal: true

require 'spec_helper'

describe ProcessSettings do
  describe '[] operator' do
    let(:instance) { double("instance", '[]': nil)}

    it 'delegates to Monitor.instance with defaults' do
      expect(instance).to receive(:[]).with('gem', 'listen', 'log_level', dynamic_context: {}, required: true).and_return('info')
      described_class::Monitor.instance = instance

      result = described_class['gem', 'listen', 'log_level']
      expect(result).to eq('info')
    end

    it 'delegates to Monitor.instance with pass-through' do
      expect(instance).to receive(:[]).with('gem', 'listen', 'log_level', dynamic_context: { cuid: '1234'}, required: false).and_return(nil)
      described_class::Monitor.instance = instance

      result = described_class['gem', 'listen', 'log_level', dynamic_context: { cuid: '1234' }, required: false]
      expect(result).to be_nil
    end
  end
end
