# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'process_settings/replace_versioned_file'

describe ProcessSettings::ReplaceVersionedFile do
  let(:combined_settings_v16)    { "spec/fixtures/production/combined_process_settings-16.yml" }
  let(:combined_settings_v16_0)  { "spec/fixtures/production/combined_process_settings-16-0.yml" }
  let(:combined_settings_v16_50) { "spec/fixtures/production/combined_process_settings-16-50.yml" }
  let(:combined_settings_v18)    { "spec/fixtures/production/combined_process_settings-18.yml" }
  let(:combined_settings_v18_1)  { "spec/fixtures/production/combined_process_settings-18-1.yml" }

  describe "replace_file_on_newer_file_version" do
    context "when source file exists but destination does not" do
      it "should replace the file" do
        params = [combined_settings_v18, "spec/fixtures/production/combined_process_settings-xxx.yml"]

        expect(FileUtils).to receive(:mv).with(*params)
        expect(FileUtils).to_not receive(:remove_file)
        described_class.replace_file_on_newer_file_version(*params)
      end
    end

    context "when source file does not exists" do
      it "should replace the file" do
        params = ["spec/fixtures/production/combined_process_settings-xxx.yml", combined_settings_v18]

        expect(FileUtils).to_not receive(:mv).with(*params)
        expect(FileUtils).to_not receive(:remove_file)
        described_class.replace_file_on_newer_file_version(*params)
      end
    end

    context "when source major verion is greater than destination major version" do
      it "should replace the file" do
        params = [combined_settings_v18, combined_settings_v16]

        expect(FileUtils).to receive(:mv).with(*params)
        expect(FileUtils).to_not receive(:remove_file)
        described_class.replace_file_on_newer_file_version(*params)
      end

      context "when source minor version is not specified and destination minor version is specified" do
        it "should replace the file" do
          params = [combined_settings_v18, combined_settings_v16_50]

          expect(FileUtils).to receive(:mv).with(*params)
          expect(FileUtils).to_not receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is specified and destination minor version is not specified" do
        it "should replace the file" do
          params = combined_settings_v18_1, combined_settings_v16

          expect(FileUtils).to receive(:mv).with(*params)
          expect(FileUtils).to_not receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is less than destination minor version" do
        it "should replace the file" do
          params = combined_settings_v18_1, combined_settings_v16_50

          expect(FileUtils).to receive(:mv).with(*params)
          expect(FileUtils).to_not receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is greater than destination minor version" do
        it "should replace the file" do
          params = combined_settings_v18_1, combined_settings_v16_0

          expect(FileUtils).to receive(:mv).with(*params)
          expect(FileUtils).to_not receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end
    end

    context "when source major verion is equal to destination major version and no minor versions" do
      it "should not replace the file" do
        params = [combined_settings_v16, combined_settings_v16]

        expect(FileUtils).to_not receive(:mv).with(*params)
        expect(FileUtils).to_not receive(:remove_file)
        described_class.replace_file_on_newer_file_version(*params)
      end

      context "when source minor version is not specified and destination minor version is zero" do
        it "should not replace the file" do
          params = [combined_settings_v16, combined_settings_v16_0]

          expect(FileUtils).to_not receive(:mv).with(*params)
          expect(FileUtils).to receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is zero and destination minor version is not specified" do
        it "should not replace the file" do
          params = combined_settings_v16_0, combined_settings_v16

          expect(FileUtils).to_not receive(:mv).with(*params)
          expect(FileUtils).to receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is not specified and destination minor version is greater than zero" do
        it "should not replace the file" do
          params = [combined_settings_v16, combined_settings_v16_50]

          expect(FileUtils).to_not receive(:mv).with(*params)
          expect(FileUtils).to receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is greater than zero and destination minor version is not specified" do
        it "should replace the file" do
          params = combined_settings_v16_50, combined_settings_v16

          expect(FileUtils).to receive(:mv).with(*params)
          expect(FileUtils).to_not receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is less than destination minor version" do
        it "should not replace the file" do
          params = combined_settings_v16_0, combined_settings_v16_50

          expect(FileUtils).to_not receive(:mv).with(*params)
          expect(FileUtils).to receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is greater than destination minor version" do
        it "should replace the file" do
          params = combined_settings_v16_50, combined_settings_v16_0

          expect(FileUtils).to receive(:mv).with(*params)
          expect(FileUtils).to_not receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end
    end

    context "when source major verion is less than destination major version" do
      it "should not replace the file" do
        params = [combined_settings_v16, combined_settings_v18]

        expect(FileUtils).to_not receive(:mv).with(*params)
        expect(FileUtils).to receive(:remove_file)
        described_class.replace_file_on_newer_file_version(*params)
      end

      context "when source minor version is not specified and destination minor is not zero" do
        it "should not replace the file" do
          params = [combined_settings_v16, combined_settings_v18_1]

          expect(FileUtils).to_not receive(:mv).with(*params)
          expect(FileUtils).to receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is not zero and destination minor version is not specified" do
        it "should not replace the file" do
          params = combined_settings_v16_50, combined_settings_v18

          expect(FileUtils).to_not receive(:mv).with(*params)
          expect(FileUtils).to receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is less than destination minor version" do
        it "should not replace the file" do
          params = combined_settings_v16_0, combined_settings_v18_1

          expect(FileUtils).to_not receive(:mv).with(*params)
          expect(FileUtils).to receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end

      context "when source minor version is greater than destination minor version" do
        it "should not replace the file" do
          params = combined_settings_v16_50, combined_settings_v18_1

          expect(FileUtils).to_not receive(:mv).with(*params)
          expect(FileUtils).to receive(:remove_file)
          described_class.replace_file_on_newer_file_version(*params)
        end
      end
    end
  end
end
