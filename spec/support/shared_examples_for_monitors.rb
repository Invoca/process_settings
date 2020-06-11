# frozen_string_literal: true

# RSpec shared examples for ProcessSettings::Monitor
RSpec.shared_examples "AbstractMonitor" do |settings, logger, scoped_setting|
  let(:monitor) do
    allow(ActiveSupport::Deprecation).to receive(:warn).with(anything, :initialize)
    allow_any_instance_of(ActiveSupport::Deprecation).to receive(:deprecation_warning).with(any_args)
    described_class.new(settings, logger: logger)
  end

  describe "#initialize" do
    subject { monitor }

    it { should be_a(ProcessSettings::AbstractMonitor) }

    it "defaults to empty static context" do
      expect(monitor.static_context).to eq({})
    end

    it "raises ArgumentError if logger: nil" do
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:deprecation_warning).with(any_args)
      expect { described_class.new([], logger: nil) }.to raise_exception(ArgumentError, /logger must be not be nil/)
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
