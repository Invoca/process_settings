# frozen_string_literal: true

require "appraisal/matrix"

appraisal_matrix(activesupport: "7.0") do |activesupport:|
  if activesupport < Gem::Version.new("7.1")
    gem "benchmark"
  end
end
