# encoding: utf-8

# Set up gem loading (necessary for cri dependency)
require File.dirname(__FILE__) + '/gem_loader.rb'

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
require 'nanoc'
require 'nanoc/cli'
require 'nanoc/tasks'

# Load miscellaneous requirements
require 'stringio'

module Nanoc::TestHelpers

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
    # Build site name
    site_name = params[:name]
    if site_name.nil?
      @site_num ||= 0
      site_name = "site-#{@site_num}"
      @site_num += 1
    end

    # Build rules
    rules_content = <<EOS
compile '*' do
  {{compilation_rule_content}}
end

route '*' do
  if item.binary?
    item.identifier.chop + (item[:extension] ? '.' + item[:extension] : '')
  else
    item.identifier + 'index.html'
  end
end

layout '*', :erb
EOS
    rules_content.gsub!('{{compilation_rule_content}}', params[:compilation_rule_content] || '')

    # Create site
    unless File.directory?(site_name)
      FileUtils.mkdir_p(site_name)
      FileUtils.cd(site_name) do
        FileUtils.mkdir_p('content')
        FileUtils.mkdir_p('layouts')
        FileUtils.mkdir_p('lib')
        FileUtils.mkdir_p('output')

        if params[:has_layout]
          File.open('layouts/default.html', 'w') do |io|
            io.write('... <%= @yield %> ...')
          end
        end

        File.open('config.yaml', 'w') { |io| io.write('stuff: 12345') }
        File.open('Rules', 'w') { |io| io.write(rules_content) }
      end
    end

    # Yield site
    FileUtils.cd(site_name) do
      yield Nanoc::Site.new('.')
    end
  end

  def setup
    # Check skipped
    if ENV['skip']
      if ENV['skip'].split(',').include?(self.class.to_s)
        skip 'manually skipped'
      end
    end

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

    # Let us get to the raw errors
    Nanoc::CLI::ErrorHandler.disable
  end

  def teardown
    # Restore normal error handling
    Nanoc::CLI::ErrorHandler.enable

    # Exit tmp
    FileUtils.cd('..')
    FileUtils.rm_rf('tmp')

    # Go unquiet
    unless ENV['QUIET'] == 'false'
      $stdout = STDOUT
      $stderr = STDERR
    end
  end

  def capturing_stdio(&block)
    # Store
    orig_stdout = $stdout
    orig_stderr = $stderr

    # Run
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    { :stdout => $stdout.string, :stderr => $stderr.string }
  ensure
    # Restore
    $stdout = orig_stdout
    $stderr = orig_stderr
  end

  # Adapted from http://github.com/lsegal/yard-examples/tree/master/doctest
  def assert_examples_correct(object)
    P(object).tags(:example).each do |example|
      # Classify
      lines = example.text.lines.map do |line|
        [ line =~ /^\s*# ?=>/ ? :result : :code, line ]
      end

      # Join
      pieces = []
      lines.each do |line|
        if !pieces.empty? && pieces.last.first == line.first
          pieces.last.last << line.last
        else
          pieces << line
        end
      end
      lines = pieces.map { |p| p.last }

      # Test
      b = binding
      lines.each_slice(2) do |pair|
        actual_out   = eval(pair.first, b)
        expected_out = eval(pair.last.match(/# ?=>(.*)/)[1], b)
      
        assert_equal expected_out, actual_out,
          "Incorrect example:\n#{pair.first}"
      end
    end
  end

  def assert_contains_exactly(expected, actual)
    assert_equal expected.size, actual.size,
      'Expected %s to be of same size as %s' % [actual.inspect, expected.inspect]
    remaining = actual.dup.to_a
    expected.each do |e|
      index = remaining.index(e)
      remaining.delete_at(index) if index
    end
    assert remaining.empty?,
      'Expected %s to contain all the elements of %s' % [actual.inspect, expected.inspect]
  end

end

# Unexpected system exit is unexpected
::MiniTest::Unit::TestCase::PASSTHROUGH_EXCEPTIONS.delete(SystemExit)

# A more precise inspect method for Time improves assert failure messages.
#
class Time
  def inspect
    strftime("%a %b %d %H:%M:%S.#{"%06d" % usec} %Z %Y")
  end
end
