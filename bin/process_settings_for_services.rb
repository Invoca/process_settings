#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/process_settings/targeted_process_settings'
require 'optparse'
require 'ostruct'
require 'yaml'
require 'set'

require 'pry'

CORRELATION_KEYS = [
  ['node'],
  ['app'],
  ['region'],
  ['app', 'node'],
  ['app', 'region'],
  ['deployGroup'],
  ['app', 'deployGroup']
].freeze

PROGRAM_NAME = File.basename($PROGRAM_NAME)

def parse_options(argv)
  options = OpenStruct.new
  options.verbose = false
  option_parser = OptionParser.new(argv) do |opt|
    opt.op('-o', '--output', 'Output file.') { |o| options.output_filename = o }
  end

  if option_parser.parse! && argv.size == 3 && options.output_filename
    argv
  else
    warn "usage: #{PROGRAM_NAME} <path-to-flat_services.yml> <path-to-combined_process_settings-OLD.yml <path-to-combined_process_settings-NEW.yml -o output_filename"
    option_parser.summarize(STDERR)
    exit(1)
  end
end


#
# main
#
path_to_flat_services_yml, path_to_combined_process_settings_yml_old, path_to_combined_process_settings_yml_new = parse_options(ARGV.dup)

flat_services_yml_json_doc     = YAML.load_file(path_to_flat_services_yml)
combined_process_settings_yml_json_doc_old = YAML.load_file(path_to_combined_process_settings_yml_old)
combined_process_settings_yml_json_doc_new = YAML.load_file(path_to_combined_process_settings_yml_new)

targeted_process_settings_old = ProcessSettings::TargetedProcessSettings.from_array(combined_process_settings_yml_json_doc_old)
targeted_process_settings_new = ProcessSettings::TargetedProcessSettings.from_array(combined_process_settings_yml_json_doc_new)

flat_services_with_targeted_settings = Hash.new { |h, service| h[service] = Hash.new { |h2, node| h2[node] = [] } }

correlation_scorecard = Hash.new { |h, k| h[k] = { false => Set.new, true => Set.new } }

flat_services_yml_json_doc.each do |service, nodes|
  nodes.each do |node, pods|
    pods.each_with_index do |pod_context, pod_index|
      node_attrs = pod_context.dup
      node_attrs['service']   = service
      node_attrs['node']      = node
      node_attrs['pod_index'] = pod_index if pods.size > 1
      node_targeted_process_settings_old = targeted_process_settings_old.with_static_context(pod_context)
      node_targeted_process_settings_new = targeted_process_settings_new.with_static_context(pod_context)

      flat_services_with_targeted_settings[service][node] << node_attrs

      if (changed = node_targeted_process_settings_old != node_targeted_process_settings_new)
        node_old =  node_targeted_process_settings_old.map do |node_targeted_process_setting|
                      {
                        'target'            => node_targeted_process_setting.target,
                        "process_settings"  => node_targeted_process_setting.process_settings
                      }
                    end
        node_new =  node_targeted_process_settings_new.map do |node_targeted_process_setting|
                      {
                        'target'            => node_targeted_process_setting.target,
                        "process_settings"  => node_targeted_process_setting.process_settings
                      }
                    end

        node_attrs['__changes__'] = {
          'old' => node_old,
          'new' => node_new
        }
        node_attrs['__changes__']['pod_index'] = pod_index if pods.size > 1
      end

      CORRELATION_KEYS.each do |correlation_key|
        scorecard = correlation_scorecard[correlation_key]

        correlation_key_values = correlation_key.map { |key| { key => node_attrs[key] } }
        scorecard[changed] << correlation_key_values
      end
    end
  end
end


perfect_correlations = correlation_scorecard.select do |_correllation_key, scorecard|
  (scorecard[false] & scorecard[true]).empty?
end

best_correlation = perfect_correlations.min_by { |_correllation_key, scorecard| scorecard[true].size }

puts best_correlation.first.inspect, best_correlation.last[true].to_a.inspect

puts flat_services_with_targeted_settings.to_yaml
