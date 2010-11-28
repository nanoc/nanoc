# encoding: utf-8

# Load unit testing stuff
begin
  require 'minitest/unit'
  require 'minitest/spec'
  require 'minitest/mock'
  require 'mocha'
rescue => e
  $stderr.puts "To run the nanoc unit tests, you need minitest and mocha."
  raise e
end

# Load nanoc
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
require 'nanoc3'
require 'nanoc3/cli'
require 'nanoc3/tasks'

# Load miscellaneous requirements
require 'stringio'

module Nanoc3::TestHelpers

  def if_have(*libs)
    libs.each do |lib|
      begin
        require lib
      rescue LoadError
        skip "requiring #{lib} failed"
        return
      end
    end

    yield
  end

  def if_implemented
    begin
      yield
    rescue NotImplementedError, NameError
      skip $!
      return
    end
  end

  def with_site(params={})
    site_name = 'my_test_site'

    rules_content = <<EOS
compile '*' do
  {{compilation_rule_content}}
end

route '*' do
  if item.binary?
    item.identifier.chop + '.' + item[:extension]
  else
    item.identifier + 'index.html'
  end
end

layout '*', :erb
EOS
  rules_content.gsub!('{{compilation_rule_content}}', params[:compilation_rule_content] || '')

    FileUtils.mkdir_p(site_name)
    FileUtils.cd(site_name) do
      FileUtils.mkdir_p('content')
      FileUtils.mkdir_p('layouts')
      FileUtils.mkdir_p('lib')
      FileUtils.mkdir_p('output')

      File.open('config.yaml', 'w') { |io| io.write('stuff: 12345') }
      File.open('Rules', 'w') { |io| io.write(rules_content) }
      
      yield Nanoc3::Site.new('.')
    end
  end

  def setup
    # Clean up
    GC.start

    # Go quiet
    unless ENV['QUIET'] == 'false'
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    # Enter tmp
    FileUtils.mkdir_p('tmp')
    FileUtils.cd('tmp')
  end

  def teardown
    # Exit tmp
    FileUtils.cd('..')
    FileUtils.rm_rf('tmp')

    # Go unquiet
    unless ENV['QUIET'] == 'false'
      $stdout = STDOUT
      $stderr = STDERR
    end
  end

  # Adapted from http://github.com/lsegal/yard-examples/tree/master/doctest
  def assert_examples_correct(object)
    P(object).tags(:example).each do |example|
      begin
        # Get input and output
        parts = example.text.split(/# ?=>/).map { |s| s.strip }
        code             = parts[0].strip
        expected_out_raw = parts[1].strip

        # Evaluate
        expected_out     = eval(parts[1])
        actual_out       = instance_eval("#{code}")
      rescue Exception => e
        e.message << " (code: #{code}; expected output: #{expected_out_raw})"
        raise e
      end

      assert_equal expected_out, actual_out,
        "Incorrect example: #{code}"
    end
  end

end
