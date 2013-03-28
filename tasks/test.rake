# encoding: utf-8

require 'minitest/unit'

dirs = [ 'test'] + Dir['test/**/*'].select { |fn| File.directory?(fn) }
dirs.each do |dir|
  desc "Run all #{dir} tests"
  task dir.gsub('/', ':') do |task|
    ENV['QUIET'] ||= 'true'
    $VERBOSE = (ENV['VERBOSE'] == 'true')

    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

    require 'test/helper'

    test_files = Dir["#{dir}/**/*_spec.rb"] + Dir["#{dir}/**/test_*.rb"]
    test_files.each { |f| require f }

    exit MiniTest::Unit.new.run($VERBOSE ? %w( --verbose ) : %w())
  end
end
