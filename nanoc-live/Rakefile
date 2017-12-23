# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
end

task test: :spec

task :gem do
  sh('gem build *.gemspec')
end

task default: %i[test rubocop]
