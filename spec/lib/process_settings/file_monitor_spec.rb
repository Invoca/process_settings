# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'support/shared_examples_for_monitors'

describe ProcessSettings::FileMonitor do
  SETTINGS_PATH = "./settings.yml"
  SAMPLE_SETTINGS = [{ 'target' => true, 'settings' => { 'sip' => { 'enabled' => true } } }, { 'meta' => { 'version' => 19, 'END' => true } }].freeze
  EAST_SETTINGS = [{ 'target' => { 'region' => 'east' }, 'settings' => { 'reject_call' => true } },
                   { 'target' => true, 'settings' => { 'sip' => { 'enabled' => true } } },
                   { 'target' => { 'caller_id' => ['+18003334444', '+18887776666']}, 'settings' => { 'reject_call' => false }},
                   { 'target' => { 'region' => 'east', 'caller_id' => ['+18003334444', '+18887776666'] }, 'settings' => { 'collective' => true }},
                   { 'meta' => { 'version' => 19, 'END' => true }}].freeze
  EMPTY_SAMPLE_SETTINGS = [{ 'target' => true, 'settings' => {} }, { 'meta' => { 'version' => 19, 'END' => true }}].freeze
  SAMPLE_SETTINGS_YAML = SAMPLE_SETTINGS.to_yaml
  EAST_SETTINGS_YAML = EAST_SETTINGS.to_yaml
  EMPTY_SAMPLE_SETTINGS_YAML = EMPTY_SAMPLE_SETTINGS.to_yaml

  let(:logger) { Logger.new(STDERR).tap { |logger| logger.level = ::Logger::ERROR } }

  RSpec.configuration.before(:each) do
    Listen.stop
  end

  RSpec.configuration.after(:each) do
    Listen.stop
  end

  describe "default behavior" do
    before { File.write(settings_file, EAST_SETTINGS_YAML) }
    after  { FileUtils.rm_f(settings_file) }

    let(:settings_file) { File.expand_path(SETTINGS_PATH, __dir__) }
    let(:monitor) { described_class.new(settings_file, logger: logger) }

    it_should_behave_like(
      "AbstractMonitor",
      File.expand_path(SETTINGS_PATH, __dir__),
      Logger.new(STDERR).tap { |logger| logger.level = ::Logger::ERROR },
      ['sip', 'enabled']
    )

    describe "#file_path" do
      subject { monitor.file_path }

      it { should eq(settings_file) }
    end
  end

  describe "#untargeted_settings" do
    before do
      File.write(SETTINGS_PATH, SAMPLE_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "should read from disk the first time" do
      process_monitor = described_class.new(SETTINGS_PATH, logger: logger)
      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.target.json_doc).to eq(SAMPLE_SETTINGS.first['target'])
      expect(matching_settings.first.settings.instance_variable_get(:@json_doc)).to eq(SAMPLE_SETTINGS.first['settings'])
    end

    { modified: [File.expand_path(SETTINGS_PATH), [], []], added: [[], File.expand_path(SETTINGS_PATH), []] }.each do |type, args|
      it "should re-read from disk when callback triggered with #{type}" do
        file_change_notifier_stub = Object.new
        class << file_change_notifier_stub
          def to(path)
          end
        end

        listener_stub = Object.new
        class << listener_stub
          def start
          end
        end

        block = nil
        expect(file_change_notifier_stub).to receive(:to).with(File.expand_path('.')) { |&blk| block = blk; listener_stub }
        expect_any_instance_of(described_class).to receive(:file_change_notifier) { file_change_notifier_stub }

        process_monitor = described_class.new(SETTINGS_PATH, logger: logger)

        expect(process_monitor).to receive(:load_untargeted_settings) { }

        block.call(*args)
      end
    end

    it "should re-read from disk when watcher triggered" do
      process_monitor = described_class.new(SETTINGS_PATH, logger: logger)

      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.settings.json_doc).to eq('sip' => { 'enabled' => true })

      sleep(0.15)

      File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)

      sleep(0.3)  # allow enough time for the listen gem to notify us of the changed file

      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.first.settings.json_doc).to eq({})
    end
  end

  context "with process_settings" do
    subject(:process_monitor) { described_class.new(SETTINGS_PATH, logger: logger) }

    before do
      File.write(SETTINGS_PATH, EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    describe "#static_context =" do
      it "rejects symbol keys" do
        expect { process_monitor.static_context = { service_name: "frontend" } }.to raise_exception(ArgumentError, /symbol key :service_name found--should be String/)
      end

      it "rejects symbol values" do
        expect { process_monitor.static_context = { "service_name" => :frontend } }.to raise_exception(ArgumentError, /symbol value :frontend found--should be String/)
      end

      it "rejects symbol values in arrays" do
        expect { process_monitor.static_context = { "service_name" => ["database", :frontend] } }.to raise_exception(ArgumentError, /symbol value :frontend found--should be String/)
      end

      it "rejects nested symbol keys" do
        expect { process_monitor.static_context = { "top" => { service_name: "frontend" } } }.to raise_exception(ArgumentError, /symbol key :service_name found--should be String/)
      end

      it "rejects nested symbol keys" do
        expect { process_monitor.static_context = { "top" => { "service_name" => :frontend } } }.to raise_exception(ArgumentError, /symbol value :frontend found--should be String/)
      end
    end

    describe "#when_updated" do
      it 'calls back to block once when registered (by default)' do
        when_updated_proc_1 = Proc.new { true }
        when_updated_proc_2 = Proc.new { true }

        expect(when_updated_proc_1).to receive(:call).with(process_monitor)
        expect(when_updated_proc_2).to receive(:call).with(process_monitor)

        process_monitor.when_updated(&when_updated_proc_1)
        process_monitor.when_updated(&when_updated_proc_2)
      end

      it 'calls back to block once when registered (initial_update: true)' do
        when_updated_proc_1 = Proc.new { true }
        when_updated_proc_2 = Proc.new { true }

        expect(when_updated_proc_1).to receive(:call).with(process_monitor)
        expect(when_updated_proc_2).to receive(:call).with(process_monitor)

        process_monitor.when_updated(initial_update: true, &when_updated_proc_1)
        process_monitor.when_updated(initial_update: true, &when_updated_proc_2)
      end

      it 'does not call back to block when registered (initial_update: false)' do
        when_updated_proc_1 = Proc.new { true }
        when_updated_proc_2 = Proc.new { true }

        expect(when_updated_proc_1).to_not receive(:call).with(process_monitor)
        expect(when_updated_proc_2).to_not receive(:call).with(process_monitor)

        process_monitor.when_updated(initial_update: false, &when_updated_proc_1)
        process_monitor.when_updated(initial_update: false, &when_updated_proc_2)
      end

      it 'passes the current instance to the block for initial update' do
        process_monitor.when_updated(initial_update: true) do |instance|
          expect(instance).to eq(process_monitor)
        end
      end

      it 'is idempotent' do
        when_updated_proc = Proc.new { true }
        expect(when_updated_proc).to receive(:call).with(process_monitor)

        process_monitor.when_updated(&when_updated_proc)
        process_monitor.when_updated(&when_updated_proc)
      end

      it 'calls back to each block when static_context changes' do
        when_updated_proc_1 = Proc.new { true }
        when_updated_proc_2 = Proc.new { true }

        expect(when_updated_proc_1).to receive(:call).with(process_monitor).exactly(2)
        expect(when_updated_proc_2).to receive(:call).with(process_monitor).exactly(2)

        process_monitor.when_updated(&when_updated_proc_1)
        process_monitor.when_updated(&when_updated_proc_2)
        process_monitor.static_context = { 'region' => 'west' }
      end

      it 'calls back to each block when the file changes' do
        when_updated_proc_1 = Proc.new { true }
        when_updated_proc_2 = Proc.new { true }

        expect(when_updated_proc_1).to receive(:call).with(process_monitor).exactly(2)
        expect(when_updated_proc_2).to receive(:call).with(process_monitor).exactly(2)

        process_monitor.when_updated(&when_updated_proc_1)
        process_monitor.when_updated(&when_updated_proc_2)

        sleep(0.15)
        File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)
        sleep(0.3)  # allow enough time for the listen gem to notify us of the changed file
      end

      it 'does not call back to the blocks on a noop change' do
        when_updated_proc_1 = Proc.new { true }
        when_updated_proc_2 = Proc.new { true }

        expect(when_updated_proc_1).to receive(:call).with(process_monitor)
        expect(when_updated_proc_2).to receive(:call).with(process_monitor)

        process_monitor.when_updated(&when_updated_proc_1)
        process_monitor.when_updated(&when_updated_proc_2)

        sleep(0.15)
        File.write(SETTINGS_PATH, EAST_SETTINGS_YAML)
        sleep(0.3)  # allow enough time for the listen gem to notify us of the changed file
      end

      it "keeps going even if exceptions raised" do
        when_updated_proc_1 = Proc.new { true }
        when_updated_proc_2 = Proc.new { true }

        expect(when_updated_proc_1).to receive(:call).with(process_monitor).and_raise(StandardError, 'oops 1').exactly(2)
        expect(when_updated_proc_2).to receive(:call).with(process_monitor).and_raise(StandardError, 'oops 2').exactly(2)

        process_monitor.when_updated(&when_updated_proc_1)
        process_monitor.when_updated(&when_updated_proc_2)

        expect(logger).to receive(:error).with("ProcessSettings::Monitor#call_when_updated_blocks rescued exception:\nStandardError: oops 1")
        expect(logger).to receive(:error).with("ProcessSettings::Monitor#call_when_updated_blocks rescued exception:\nStandardError: oops 2")

        sleep(0.15)
        File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)
        sleep(0.3)  # allow enough time for the listen gem to notify us of the changed file
      end
    end

    describe "#on_change" do
      let(:callbacks) { [] }
      let(:callback_1) { process_monitor.on_change { callbacks << 1 } }
      let(:callback_2) { process_monitor.on_change { callbacks << 2 } }

      before(:each) do
        expect(ProcessSettings::OnChangeDeprecation).to receive(:deprecation_warning).with(:on_change, :when_updated).at_least(1)
      end

      it "runs all the callbacks on static_context change" do
        process_monitor.static_context = { 'region' => 'east' }

        callback_1
        callback_2

        process_monitor.static_context = { 'region' => 'west' }

        expect(callbacks).to eq([1, 2])
      end

      it "runs all the callbacks on disk change" do
        process_monitor

        process_monitor.static_context = { 'region' => 'east' }

        callback_1
        callback_2

        sleep(0.15)

        File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)

        sleep(0.3)  # allow enough time for the listen gem to notify us of the changed file

        expect(callbacks).to eq([1, 2])
      end

      it "doesn't run all the callbacks on no-op disk change" do
        process_monitor.static_context = { 'region' => 'east' }

        callback_1
        callback_2

        File.write(SETTINGS_PATH, EAST_SETTINGS_YAML)

        expect(callbacks).to eq([])
      end

      it "keeps going even if exceptions raised" do
        process_monitor.static_context = { 'region' => 'east' }

        process_monitor.on_change { raise 'callback_1' }
        process_monitor.on_change { raise 'callback_2' }

        expect(logger).to receive(:error).with("ProcessSettings::Monitor#notify_on_change rescued exception:\nRuntimeError: callback_1")
        expect(logger).to receive(:error).with("ProcessSettings::Monitor#notify_on_change rescued exception:\nRuntimeError: callback_2")

        sleep(0.15)

        File.write(SETTINGS_PATH, EMPTY_SAMPLE_SETTINGS_YAML)

        expect(callbacks).to eq([])

        sleep(0.3)  # allow enough time for the listen gem to notify us of the changed file
      end
    end
  end

  describe "#statically_targeted_settings" do
    let(:process_monitor) { described_class.new(SETTINGS_PATH, logger: logger) }

    before do
      File.write(SETTINGS_PATH, EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "keeps all entries when targeted" do
      process_monitor.static_context = { 'region' => 'east' }

      result = process_monitor.statically_targeted_settings
      settings = result.map { |s| s.settings.json_doc }

      expect(settings).to eq([{ 'reject_call' => true }, { 'sip' => { 'enabled' => true } }, { 'reject_call' => false }, { 'collective' => true }])
    end

    it "keeps subset of targeted entries" do
      process_monitor.static_context = { 'region' => 'west' }

      result = process_monitor.statically_targeted_settings
      settings = result.map { |s| s.settings.json_doc }

      expect(settings).to eq([{ 'sip' => { 'enabled' => true } }, {"reject_call" => false}])
    end

    it "recomputes targeting if static_context changes" do
      process_monitor.static_context = { 'region' => 'west' }

      result = process_monitor.statically_targeted_settings
      result2 = process_monitor.statically_targeted_settings
      expect(result2.object_id).to eq(result.object_id)

      process_monitor.static_context = { 'region' => 'west' }

      result3 = process_monitor.statically_targeted_settings
      expect(result3.object_id).to_not eq(result.object_id)

      settings = result3.map { |s| s.settings.json_doc }
      expect(settings).to eq([{ 'sip' => { 'enabled' => true } }, {"reject_call" => false}])
    end
  end

  describe "#targeted_value" do
    let(:process_monitor) { described_class.new(SETTINGS_PATH, logger: logger) }

    before do
      File.write(SETTINGS_PATH, EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(SETTINGS_PATH)
    end

    it "should respect static targeting with dynamic overrides" do
      process_monitor.static_context = { 'region' => 'east' }

      expect(process_monitor.targeted_value('sip', 'enabled', dynamic_context: {})).to eq(true)

      expect(process_monitor.targeted_value('reject_call', dynamic_context: {})).to eq(true)
      expect(process_monitor.targeted_value('reject_call', dynamic_context: { 'caller_id' => '+18003334444' })).to eq(false)
      expect(process_monitor.targeted_value('reject_call', dynamic_context: { 'caller_id' => '+18887776666' })).to eq(false)
      expect(process_monitor.targeted_value('reject_call', dynamic_context: { 'caller_id' => '+12223334444' })).to eq(true)

      expect(process_monitor.targeted_value('collective', dynamic_context: {}, required: false)).to eq(nil)
      expect(process_monitor.targeted_value('collective', dynamic_context: { 'caller_id' => '+18880006666' }, required: false)).to eq(nil)
      expect(process_monitor.targeted_value('collective', dynamic_context: { 'caller_id' => '+18887776666' }, required: false)).to eq(true)
      expect(process_monitor.targeted_value('collective', dynamic_context: { 'region' => 'west', 'caller_id' => '+18880006666' }, required: false)).to eq(nil)
      expect(process_monitor.targeted_value('collective', dynamic_context: { 'region' => 'west', 'caller_id' => '+18887776666' }, required: false)).to eq(true)
    end
  end
end