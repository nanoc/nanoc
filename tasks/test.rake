require 'rspec/core/rake_task'

def run_tests(dir_glob)
  ENV['ARGS'] ||= ''
  ENV['QUIET'] ||= 'true'

  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

  # require our test helper so we don't have to in each individual test
  require 'test/helper'

  test_files = Dir["#{dir_glob}*_spec.rb"] + Dir["#{dir_glob}test_*.rb"]
  test_files.each { |f| require f }

  res = Minitest.run(ENV['ARGS'].split)
  exit(res) if res != 0
end

namespace :test do
  # test:all
  desc 'Run all tests'
  task :all do
    run_tests 'test/**/'
  end

  # test:...
  %w( base cli data_sources extra filters helpers ).each do |dir|
    desc "Run all #{dir} tests"
    task dir.to_sym do |_task|
      run_tests "test/#{dir}/**/"
    end
  end
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '-r ./spec/spec_helper.rb --color'
  t.verbose = false
end

desc 'Alias for test:all + rubocop'
task test: [:spec, :'test:all', :rubocop]
