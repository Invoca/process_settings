# frozen_string_literal: true

# RSpec shared examples for ProcessSettings::Monitor
RSpec.shared_examples "Monitor" do |settings_file, logger, settings|
  let(:monitor) { described_class.new(settings_file, logger: logger) }

  before { File.write(settings_file, settings.to_yaml) }
  after  { FileUtils.rm_f(settings_file) }

  describe "#initialize" do
    subject { monitor }

    it { should be_a(ProcessSettings::Monitor) }

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

  describe "#file_path" do
    subject { monitor.file_path }

    it { should eq(settings_file) }
  end
end
