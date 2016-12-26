require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'coveralls/rake/task'

RuboCop::RakeTask.new(:rubocop)

Coveralls::RakeTask.new

SUBDIRS = %w(* base checking cli data_sources deploying extra filters helpers).freeze

namespace :test do
  SUBDIRS.each do |dir|
    Rake::TestTask.new(dir == '*' ? 'all' : dir) do |t|
      t.test_files = Dir["test/#{dir}/**/*_spec.rb"] + Dir["test/#{dir}/**/test_*.rb"]
      t.libs = ['./lib', '.']
      t.ruby_opts = ['-r./test/helper']
    end
  end
end

RSpec::Core::RakeTask.new(:spec)

desc 'Run all tests and specs'
task test: [:spec, :'test:all', :'coveralls:push']

task default: [:test, :rubocop]
