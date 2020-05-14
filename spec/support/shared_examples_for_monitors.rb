# frozen_string_literal: true

# RSpec shared examples for ProcessSettings::Monitor
RSpec.shared_examples "AbstractMonitor" do |settings, logger, scoped_setting|
  let(:monitor) { described_class.new(settings, logger: logger) }

  describe "#initialize" do
    subject { monitor }

    it { should be_a(ProcessSettings::AbstractMonitor) }

    it "defaults to empty static context" do
      expect(monitor.static_context).to eq({})
    end
  end

  describe "#static_context" do
    subject { monitor.static_context }

    describe "when set to default" do
      it { should eq({}) }
    end
  end

  describe "#logger" do
    subject { monitor.logger }

    it { should eq(logger) }
  end

  describe "#[]" do
    subject { monitor[*scoped_setting] }

    it { should_not be_nil }
  end
end
