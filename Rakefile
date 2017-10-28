# frozen_string_literal: true

require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'coveralls/rake/task'

### coverage

Coveralls::RakeTask.new

### style

RuboCop::RakeTask.new(:rubocop)

### test

Rake::TestTask.new(:test_all) do |t|
  t.test_files = Dir['test/**/test_*.rb']
  t.libs << 'test'
  t.verbose = false
end

### spec

RSpec::Core::RakeTask.new(:spec_nanoc) do |t|
  t.verbose = false
  t.rspec_opts =
    '--options .rspec-nanoc ' \
    '--exclude-pattern spec/nanoc/live/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:spec_nanoc_live) do |t|
  t.verbose = false
  t.rspec_opts = \
    '--options .rspec-nanoc-live ' \
    '--pattern spec/nanoc/live/**/*_spec.rb'
end

task spec: %i[spec_nanoc spec_nanoc_live]

###

task test: %i[spec spec_nanoc_live test_all rubocop]
task test_ci: %i[test coveralls:push]

task default: :test
