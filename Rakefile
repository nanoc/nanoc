require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'coveralls/rake/task'

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options  = %w(--display-cop-names --format simple)
  task.patterns = ['bin/nanoc', 'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb']
end

Coveralls::RakeTask.new

SUBDIRS = %w(* base cli data_sources extra filters helpers).freeze

namespace :test do
  SUBDIRS.each do |dir|
    Rake::TestTask.new(dir == '*' ? 'all' : dir) do |t|
      t.test_files = Dir["test/#{dir}/**/*_spec.rb"] + Dir["test/#{dir}/**/test_*.rb"]
      t.libs = ['./lib', '.']
      t.ruby_opts = ['-r./test/helper']
    end
  end
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '-r ./spec/spec_helper.rb --format Fuubar --color'
  t.verbose = false
end

desc 'Run all tests and specs'
task test: [:spec, :'test:all', :'coveralls:push']

task default: [:test, :rubocop]
