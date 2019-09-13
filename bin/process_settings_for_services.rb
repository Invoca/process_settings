#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/process_settings/targeted_process_settings'
require 'yaml'

require 'pry'

PROGRAM_NAME = File.basename($PROGRAM_NAME)

def check_options(argv)
  unless argv.size == 2
    warn "usage: #{PROGRAM_NAME} <path-to-flat_services.yml> <path-to-combined_process_settings.yml"
    exit(1)
  end

  argv
end


#
# main
#
path_to_flat_services_yml, path_to_combined_process_settings_yml = check_options(ARGV.freeze)

flat_services_yml_json_doc     = YAML.load_file(path_to_flat_services_yml)
combined_process_settings_yml_json_doc = YAML.load_file(path_to_combined_process_settings_yml)

targeted_process_settings = ProcessSettings::TargetedProcessSettings.from_array(combined_process_settings_yml_json_doc)

flat_services_with_targeted_settings = {}

flat_services_yml_json_doc.each do |service, nodes|
  flat_services_with_targeted_settings[service] = {}
  nodes.each do |node, pods|
    flat_services_with_targeted_settings[service][node] ||= []
    pods.each_with_index do |pod_context, pod_index|
      node_attrs = pod_context.dup
      flat_services_with_targeted_settings[service][node] << node_attrs
      node_targeted_process_settings = targeted_process_settings.with_static_context(pod_context)

      node_attrs['__targeted_process_settings'] = []

      node_targeted_process_settings.each do |node_targeted_process_setting|
        node_attrs['__targeted_process_settings'] << {
          'target' => node_targeted_process_setting.target,
           "process_settings" => node_targeted_process_setting.process_settings
        }
      end
    end
  end
end

puts flat_services_with_targeted_settings.to_yaml
