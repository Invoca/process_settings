#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

PROGRAM_NAME = File.basename($PROGRAM_NAME)

unless ARGV.size == 1
  echo "usage: #{PROGRAM_NAME} <path-to-combined_process_settings.yml>"
  exit 1
end

path_to_combine_process_settings = ARGV[0]

unless File.exists?(path_to_combine_process_settings)
  warn "#{path_to_combine_process_settings} not found--must be a path to combined_process_settings.yml"
  exit 1
end

system("rm -f                  tmp/previous-combined_process_settings.yml") or exit 1
system("git show deployed:$1 > tmp/previous-combined_process_settings.yml") or exit 1

system("diff tmp/previous-combined_process_settings.yml $1") or exit 1
