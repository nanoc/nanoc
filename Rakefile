# frozen_string_literal: true

require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'rake/testtask'

def sub_sh(dir, cmd)
  Bundler.with_clean_env do
    Dir.chdir(dir) do
      puts "(in #{Dir.getwd})"
      sh(cmd)
    end
  end
end

namespace :nanoc do
  RuboCop::RakeTask.new(:rubocop)

  Rake::TestTask.new(:test_all) do |t|
    t.test_files = Dir['test/**/test_*.rb']
    t.libs << 'test'
    t.verbose = false
  end

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = false
  end

  task test: %i[spec test_all rubocop]

  task :gem do
    sh('gem build *.gemspec')
  end
end

namespace :nanoc_live do
  task(:test) { sub_sh('nanoc-live', 'bundle exec rake test') }
  task(:gem) { sub_sh('nanoc-live', 'bundle exec rake gem') }
end

task test: %i[nanoc:test nanoc_live:test]
task gem: %i[nanoc:gem nanoc_live:gem]
task default: :test
