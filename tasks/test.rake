# encoding: utf-8

require 'minitest/unit'

test = namespace :test do

  # test:all
  desc 'Run all tests'
  task :all do
    ENV['QUIET'] ||= 'true'

    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

    # require our test helper so we don't have to in each individual test
    require 'test/helper'

    MiniTest::Unit.autorun

    test_files = Dir['test/**/*_spec.rb'] + Dir['test/**/test_*.rb']
    test_files.each { |f| require f }
  end

  # test:...
  %w( base cli data_sources extra filters helpers tasks ).each do |dir|
    desc "Run all #{dir} tests"
    task dir.to_sym do |task|
      ENV['QUIET'] ||= 'true'

      $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

      # require our test helper so we don't have to in each individual test
      require 'test/helper'

      MiniTest::Unit.autorun

      test_files = Dir["test/#{dir}/**/*_spec.rb"] + Dir["test/#{dir}/**/test_*.rb"]
      test_files.each { |f| require f }
    end
  end

end

desc 'Alias for test:all'
task :test => [ :'test:all' ]
