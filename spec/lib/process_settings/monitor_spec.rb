# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'support/shared_examples_for_monitors'

describe ProcessSettings::Monitor do
  MONITOR_SETTINGS_PATH = "./settings#{Process.pid}.yml"
  MONITOR_SAMPLE_SETTINGS = [{ 'target' => true, 'settings' => { 'sip' => { 'enabled' => true } } }, { 'meta' => { 'version' => 19, 'END' => true } }].freeze
  MONITOR_EAST_SETTINGS = [{ 'target' => { 'region' => 'east' }, 'settings' => { 'reject_call' => true } },
                           { 'target' => true, 'settings' => { 'sip' => { 'enabled' => true } } },
                           { 'target' => { 'caller_id' => ['+18003334444', '+18887776666']}, 'settings' => { 'reject_call' => false }},
                           { 'target' => { 'region' => 'east', 'caller_id' => ['+18003334444', '+18887776666'] }, 'settings' => { 'collective' => true }},
                           { 'meta' => { 'version' => 19, 'END' => true }}].freeze
  MONITOR_EMPTY_MONITOR_SAMPLE_SETTINGS = [{ 'target' => true, 'settings' => {} }, { 'meta' => { 'version' => 19, 'END' => true }}].freeze
  MONITOR_SAMPLE_SETTINGS_YAML = MONITOR_SAMPLE_SETTINGS.to_yaml
  MONITOR_EAST_SETTINGS_YAML = MONITOR_EAST_SETTINGS.to_yaml
  MONITOR_EMPTY_MONITOR_SAMPLE_SETTINGS_YAML = MONITOR_EMPTY_MONITOR_SAMPLE_SETTINGS.to_yaml

  let(:logger) { Logger.new('/dev/null').tap { |logger| logger.level = ::Logger::ERROR } }

  RSpec.configuration.before(:each) do
    Listen.stop
  end

  RSpec.configuration.after(:each) do
    Listen.stop
  end

  describe "default behavior" do
    before { File.write(settings_file, MONITOR_EAST_SETTINGS_YAML) }
    after  { FileUtils.rm_f(settings_file) }

    before do
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(anything, :initialize)
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with("initialize is deprecated and will be removed from ProcessSettings 1.0", anything)
    end

    let(:settings_file) { File.expand_path(MONITOR_SETTINGS_PATH, __dir__) }
    let(:monitor) do
      described_class.new(settings_file, logger: logger)
    end

    it_should_behave_like(
      "AbstractMonitor",
      File.expand_path(MONITOR_SETTINGS_PATH, __dir__),
      Logger.new(STDERR).tap { |logger| logger.level = ::Logger::ERROR },
      ['sip', 'enabled']
    )

    describe "#file_path" do
      subject { monitor.file_path }

      it { should eq(settings_file) }
    end
  end

  describe "class methods" do
    describe '[] operator' do
      subject(:process_monitor) do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(anything, :initialize)
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with("initialize is deprecated and will be removed from ProcessSettings 1.0", anything)
        described_class.new(MONITOR_SETTINGS_PATH, logger: logger)
      end

      before do
        File.write(MONITOR_SETTINGS_PATH, MONITOR_EAST_SETTINGS_YAML)
      end

      after do
        FileUtils.rm_f(MONITOR_SETTINGS_PATH)
      end

      it 'delegates to the current monitor instance' do
        expect(subject).to receive(:targeted_value).with('setting1', 'sub', 'enabled', dynamic_context: { "hello" => "world" }, required: true).and_return(true)
        expect(subject['setting1', 'sub', 'enabled', dynamic_context: { "hello" => "world" }]).to eq(true)
      end

      it 'passes required: keyword arg' do
        expect(subject).to receive(:targeted_value).with('setting1', dynamic_context: { "hello" => "world" }, required: false).and_return(true)
        expect(subject['setting1', dynamic_context: { "hello" => "world" }, required: false]).to eq(true)
      end

      it 'defaults dynamic context to an empty hash' do
        expect(subject).to receive(:targeted_value).with('setting1', 'enabled', dynamic_context: {}, required: true).and_return(true)
        expect(subject['setting1', 'enabled']).to eq(true)
      end
    end

    describe ".instance method" do
      before do
        described_class.clear_instance
      end

      it "should raise an exception if not configured" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        described_class.file_path = nil

        expect do
          described_class.instance
        end.to raise_exception(ArgumentError, /::file_path must be set before calling instance method/)
      end

      it "should raise an exception if logger not set" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        described_class.file_path = "./spec/fixtures/production/combined_process_settings.yml"

        expect do
          described_class.instance
        end.to raise_exception(ArgumentError, /::logger must be set before calling instance method/)
      end

      it "should not raise an exception about file_path or logger if configured" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        described_class.file_path = nil
        described_class.logger = nil
        instance_stub = Object.new
        described_class.instance = instance_stub

        expect(described_class.instance).to eq(instance_stub)
      end

      it "logger = should set the Listen logger" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        Listen.logger = nil
        described_class.logger = logger
        expect(Listen.logger).to be(logger)
      end

      it "logger = should leave the Listen logger alone if already set" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        existing_logger = Logger.new(STDOUT)
        Listen.logger = existing_logger
        described_class.logger = logger
        expect(Listen.logger).to be(existing_logger)
        Listen.logger = nil
      end

      it "should return a global instance" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        described_class.file_path = "./spec/fixtures/production/combined_process_settings.yml"
        described_class.logger = logger

        instance_1 = described_class.instance
        instance_2 = described_class.instance

        expect(instance_1).to be_kind_of(described_class)
        expect(instance_1.object_id).to eq(instance_2.object_id)
      end

      it "should start listener depending on DISABLE_LISTEN_CHANGE_MONITORING variable" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        file_path = "./spec/fixtures/production/combined_process_settings.yml"

        allow(ENV).to receive(:[]).with("SERVICE_ENV").and_return("test")
        allow(ENV).to receive(:[]).with("DISABLE_LISTEN_CHANGE_MONITORING").and_return("1")
        instance = ProcessSettings::FileMonitor.new(file_path, logger: logger)
        expect(instance.instance_variable_get(:@listener)).to be_nil
        allow(ENV).to receive(:[]).with("SERVICE_ENV").and_return(nil)
        allow(ENV).to receive(:[]).with("DISABLE_LISTEN_CHANGE_MONITORING").and_return("0")
        instance = ProcessSettings::FileMonitor.new(file_path, logger: logger)
        expect(instance.instance_variable_get(:@listener).state).to eq(:processing_events)
      end
    end

    describe "clear_instance" do
      after do
        described_class.clear_instance
      end

      it "stores nil into instance" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        described_class.instance
        expect(described_class.instance_variable_get(:@instance)).to be
        described_class.instance = nil
        expect(described_class.instance_variable_get(:@instance)).to_not be
      end
    end

    describe "instance=" do
      after do
        described_class.clear_instance
      end

      it "stores value into instance" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        new_instance = Object.new
        described_class.instance = new_instance
        expect(described_class.instance).to be(new_instance)
      end
    end
  end

  describe "#untargeted_settings" do
    before do
      File.write(MONITOR_SETTINGS_PATH, MONITOR_SAMPLE_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(MONITOR_SETTINGS_PATH)
    end

    it "should read from disk the first time" do
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
      process_monitor = described_class.new(MONITOR_SETTINGS_PATH, logger: logger)
      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.target.json_doc).to eq(MONITOR_SAMPLE_SETTINGS.first['target'])
      expect(matching_settings.first.settings.instance_variable_get(:@json_doc)).to eq(MONITOR_SAMPLE_SETTINGS.first['settings'])
    end

    { modified: [File.expand_path(MONITOR_SETTINGS_PATH), [], []], added: [[], File.expand_path(MONITOR_SETTINGS_PATH), []] }.each do |type, args|
      it "should re-read from disk when callback triggered with #{type}" do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
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
        expect_any_instance_of(ProcessSettings::Monitor).to receive(:file_change_notifier) { file_change_notifier_stub }

        process_monitor = described_class.new(MONITOR_SETTINGS_PATH, logger: logger)

        expect(process_monitor).to receive(:load_untargeted_settings) { }

        block.call(*args)
      end
    end

    it "should re-read from disk when watcher triggered" do
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
      process_monitor = described_class.new(MONITOR_SETTINGS_PATH, logger: logger)

      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.size).to eq(1)
      expect(matching_settings.first.settings.json_doc).to eq('sip' => { 'enabled' => true })

      sleep(0.15)

      File.write(MONITOR_SETTINGS_PATH, MONITOR_EMPTY_MONITOR_SAMPLE_SETTINGS_YAML)

      sleep(0.5)  # allow enough time for the listen gem to notify us of the changed file

      matching_settings = process_monitor.untargeted_settings.matching_settings({})
      expect(matching_settings.first.settings.json_doc).to eq({})
    end
  end

  context "with process_settings" do
    subject(:process_monitor) do
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(anything, :initialize)
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
      described_class.new(MONITOR_SETTINGS_PATH, logger: logger)
    end

    before do
      File.write(MONITOR_SETTINGS_PATH, MONITOR_EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(MONITOR_SETTINGS_PATH)
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
      subject(:process_monitor) do
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(anything, :initialize)
        allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
        described_class.new(MONITOR_SETTINGS_PATH, logger: logger, environment: 'development') # development so we can test monitoring
      end

      it 'calls back to block once when registered (by default)' do
        callback_counts = Hash.new(0)
        when_updated_proc_A = ->(_process_settings_monitor) { callback_counts[:A] += 1; true }
        when_updated_proc_B = ->(_process_settings_monitor) { callback_counts[:B] += 1; true }

        process_monitor.when_updated(&when_updated_proc_A)
        process_monitor.when_updated(&when_updated_proc_B)

        expect(callback_counts).to eq(A: 1, B: 1)
      end

      it 'calls back to block once when registered (initial_update: true)' do
        callback_counts = Hash.new(0)
        when_updated_proc_A = ->(_process_settings_monitor) { callback_counts[:A] += 1; true }
        when_updated_proc_B = ->(_process_settings_monitor) { callback_counts[:B] += 1; true }

        process_monitor.when_updated(initial_update: true, &when_updated_proc_A)
        process_monitor.when_updated(initial_update: true, &when_updated_proc_B)
      end

      it 'does not call back to block when registered (initial_update: false)' do
        callback_counts = Hash.new(0)
        when_updated_proc_A = ->(_process_settings_monitor) { callback_counts[:A] += 1; true }
        when_updated_proc_B = ->(_process_settings_monitor) { callback_counts[:B] += 1; true }

        process_monitor.when_updated(initial_update: false, &when_updated_proc_A)
        process_monitor.when_updated(initial_update: false, &when_updated_proc_B)

        expect(callback_counts).to eq({})
      end

      it 'passes the current instance to the block for initial update' do
        process_monitor.when_updated(initial_update: true) do |instance|
          expect(instance).to eq(process_monitor)
        end
      end

      it 'is idempotent' do
        callback_counts = Hash.new(0)
        when_updated_proc_A = ->(_process_settings_monitor) { callback_counts[:A] += 1; true }

        process_monitor.when_updated(&when_updated_proc_A)
        process_monitor.when_updated(&when_updated_proc_A)

        expect(callback_counts).to eq(A: 1)
      end

      it 'calls back to each block when static_context changes' do
        callback_counts = Hash.new(0)
        when_updated_proc_A = ->(_process_settings_monitor) { callback_counts[:A] += 1; true }
        when_updated_proc_B = ->(_process_settings_monitor) { callback_counts[:B] += 1; true }

        process_monitor.when_updated(&when_updated_proc_A)
        process_monitor.when_updated(&when_updated_proc_B)
        process_monitor.static_context = { 'region' => 'west' }

        expect(callback_counts).to eq(A: 2, B: 2)
      end

      it 'calls back to each block when the file changes' do
        callback_counts = Hash.new(0)
        when_updated_proc_A = ->(_process_settings_monitor) { callback_counts[:A] += 1; true }
        when_updated_proc_B = ->(_process_settings_monitor) { callback_counts[:B] += 1; true }

        process_monitor.when_updated(&when_updated_proc_A)
        process_monitor.when_updated(&when_updated_proc_B)

        sleep(0.15)
        File.write(MONITOR_SETTINGS_PATH, MONITOR_EMPTY_MONITOR_SAMPLE_SETTINGS_YAML)
        sleep(0.5)  # allow enough time for the listen gem to notify us of the changed file

        expect(callback_counts).to eq(A: 2, B: 2)
      end

      it 'does not call back to the blocks on a noop change' do
        callback_counts = Hash.new(0)
        when_updated_proc_A = ->(_process_settings_monitor) { callback_counts[:A] += 1; true }
        when_updated_proc_B = ->(_process_settings_monitor) { callback_counts[:B] += 1; true }

        process_monitor.when_updated(&when_updated_proc_A)
        process_monitor.when_updated(&when_updated_proc_B)

        sleep(0.15)
        File.write(MONITOR_SETTINGS_PATH, MONITOR_EAST_SETTINGS_YAML)
        sleep(0.5)  # allow enough time for the listen gem to notify us of the changed file

        expect(callback_counts).to eq(A: 1, B: 1)
      end

      it "keeps going even if exceptions raised" do
        callback_counts = Hash.new(0)
        when_updated_proc_A = ->(_process_settings_monitor) { callback_counts[:A] += 1; raise StandardError, 'oops A' }
        when_updated_proc_B = ->(_process_settings_monitor) { callback_counts[:B] += 1; raise StandardError, 'oops B' }

        process_monitor.when_updated(&when_updated_proc_A)
        process_monitor.when_updated(&when_updated_proc_B)

        expect(logger).to receive(:error).with("ProcessSettings::Monitor#call_when_updated_blocks rescued exception:\nStandardError: oops A")
        expect(logger).to receive(:error).with("ProcessSettings::Monitor#call_when_updated_blocks rescued exception:\nStandardError: oops B")

        sleep(0.15)
        File.write(MONITOR_SETTINGS_PATH, MONITOR_EMPTY_MONITOR_SAMPLE_SETTINGS_YAML)
        sleep(0.5)  # allow enough time for the listen gem to notify us of the changed file

        expect(callback_counts).to eq(A: 2, B: 2)
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

        File.write(MONITOR_SETTINGS_PATH, MONITOR_EMPTY_MONITOR_SAMPLE_SETTINGS_YAML)

        sleep(0.5)  # allow enough time for the listen gem to notify us of the changed file

        expect(callbacks).to eq([1, 2])
      end

      it "doesn't run all the callbacks on no-op disk change" do
        process_monitor.static_context = { 'region' => 'east' }

        callback_1
        callback_2

        File.write(MONITOR_SETTINGS_PATH, MONITOR_EAST_SETTINGS_YAML)

        expect(callbacks).to eq([])
      end

      it "keeps going even if exceptions raised" do
        process_monitor.static_context = { 'region' => 'east' }

        process_monitor.on_change { raise 'callback_1' }
        process_monitor.on_change { raise 'callback_2' }

        expect(logger).to receive(:error).with("ProcessSettings::Monitor#notify_on_change rescued exception:\nRuntimeError: callback_1")
        expect(logger).to receive(:error).with("ProcessSettings::Monitor#notify_on_change rescued exception:\nRuntimeError: callback_2")

        sleep(0.15)

        File.write(MONITOR_SETTINGS_PATH, MONITOR_EMPTY_MONITOR_SAMPLE_SETTINGS_YAML)

        expect(callbacks).to eq([])

        sleep(0.5)  # allow enough time for the listen gem to notify us of the changed file
      end
    end
  end

  describe "#statically_targeted_settings" do
    let(:process_monitor) do
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(any_args)
      described_class.new(MONITOR_SETTINGS_PATH, logger: logger)
    end

    before do
      File.write(MONITOR_SETTINGS_PATH, MONITOR_EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(MONITOR_SETTINGS_PATH)
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
    let(:process_monitor) do
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(anything, :initialize)
      allow_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with("initialize is deprecated and will be removed from ProcessSettings 1.0", anything)
      described_class.new(MONITOR_SETTINGS_PATH, logger: logger)
    end

    before do
      File.write(MONITOR_SETTINGS_PATH, MONITOR_EAST_SETTINGS_YAML)
    end

    after do
      FileUtils.rm_f(MONITOR_SETTINGS_PATH)
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
