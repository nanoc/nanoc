# frozen_string_literal: true

$VERBOSE = false

require 'simplecov'
SimpleCov.start

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

require 'minitest/autorun'
require 'mocha/setup'
require 'vcr'

require 'tmpdir'
require 'stringio'
require 'yard'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

require 'nanoc'
require 'nanoc/cli'

Nanoc::CLI.setup

module Nanoc::TestHelpers
  LIB_DIR = File.expand_path(File.dirname(__FILE__) + '/../lib')

  def disable_nokogiri?
    ENV.key?('DISABLE_NOKOGIRI')
  end

  def skip_v8_on_ruby24
    if ENV.key?('DISABLE_V8')
      skip 'V8 specs are disabled (broken on Ruby 2.4)'
    end
  end

  def if_have(*libs)
    libs.each do |lib|
      if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' && lib == 'nokogiri' && disable_nokogiri?
        skip 'Pure Java Nokogiri has issues that cause problems with nanoc (see https://github.com/nanoc/nanoc/pull/422) -- run without DISABLE_NOKOGIRI to enable Nokogiri tests'
      end

      begin
        require lib
      rescue LoadError
        skip "requiring #{lib} failed"
      end
    end

    yield
  end

  def if_implemented
    yield
  rescue NotImplementedError, NameError
    skip $ERROR_INFO
    return
  end

  def with_site(params = {})
    # Build site name
    site_name = params[:name]
    if site_name.nil?
      @site_num ||= 0
      site_name = "site-#{@site_num}"
      @site_num += 1
    end

    # Build rules
    rules_content = <<~EOS
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

    rules_content =
      rules_content.gsub(
        '{{compilation_rule_content}}',
        params[:compilation_rule_content] || '',
      )

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

        File.open('nanoc.yaml', 'w') do |io|
          io << 'string_pattern_type: legacy' << "\n" if params.fetch(:legacy, true)
          io << 'data_sources:' << "\n"
          io << '  -' << "\n"
          io << '    type: filesystem' << "\n"
          io << '    identifier_type: legacy' << "\n" if params.fetch(:legacy, true)
        end

        File.open('Rules', 'w') { |io| io.write(rules_content) }
      end
    end

    # Yield site
    FileUtils.cd(site_name) do
      yield Nanoc::Int::SiteLoader.new.new_from_cwd
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
      @orig_stdout = $stdout
      @orig_stderr = $stderr

      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    # Enter tmp
    @tmp_dir = Dir.mktmpdir('nanoc-test')
    @orig_wd = FileUtils.pwd
    FileUtils.cd(@tmp_dir)

    # Let us get to the raw errors
    Nanoc::CLI::ErrorHandler.disable
  end

  def teardown
    # Restore normal error handling
    Nanoc::CLI::ErrorHandler.enable

    # Exit tmp
    FileUtils.cd(@orig_wd)
    FileUtils.rm_rf(@tmp_dir)

    # Go unquiet
    unless ENV['QUIET'] == 'false'
      $stdout = @orig_stdout
      $stderr = @orig_stderr
    end
  end

  def capturing_stdio(&_block)
    # Store
    orig_stdout = $stdout
    orig_stderr = $stderr

    # Run
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    { stdout: $stdout.string, stderr: $stderr.string }
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
        [line =~ /^\s*# ?=>/ ? :result : :code, line]
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
      lines = pieces.map(&:last)

      # Test
      b = binding
      lines.each_slice(2) do |pair|
        actual_out   = eval(pair.first, b)
        expected_out = eval(pair.last.match(/# ?=>(.*)/)[1], b)

        assert_equal(
          expected_out,
          actual_out,
          "Incorrect example:\n#{pair.first}",
        )
      end
    end
  end

  def assert_contains_exactly(expected, actual)
    assert_equal(
      expected.size,
      actual.size,
      format('Expected %s to be of same size as %s', actual.inspect, expected.inspect),
    )
    remaining = actual.dup.to_a
    expected.each do |e|
      index = remaining.index(e)
      remaining.delete_at(index) if index
    end
    assert(
      remaining.empty?,
      format('Expected %s to contain all the elements of %s', actual.inspect, expected.inspect),
    )
  end

  def assert_raises_frozen_error
    error = assert_raises(RuntimeError, TypeError) { yield }
    assert_match(/(^can't modify frozen |^unable to modify frozen object$)/, error.message)
  end

  def with_env_vars(hash, &_block)
    orig_env_hash = ENV.to_hash
    hash.each_pair { |k, v| ENV[k] = v }
    yield
  ensure
    orig_env_hash.each_pair { |k, v| ENV[k] = v }
  end

  def on_windows?
    Nanoc.on_windows?
  end

  def command?(cmd)
    which, null = on_windows? ? %w[where NUL] : ['which', '/dev/null']
    system("#{which} #{cmd} > #{null} 2>&1")
  end

  def symlinks_supported?
    File.symlink nil, nil
  rescue NotImplementedError
    return false
  rescue
    return true
  end

  def skip_unless_have_command(cmd)
    skip "Could not find external command \"#{cmd}\"" unless command?(cmd)
  end

  def skip_unless_symlinks_supported
    skip 'Symlinks are not supported by Ruby on Windows' unless symlinks_supported?
  end

  def root_dir
    File.absolute_path(File.dirname(__FILE__) + '/..')
  end
end

class Nanoc::TestCase < Minitest::Test
  include Nanoc::TestHelpers
end

# Unexpected system exit is unexpected
::Minitest::Test::PASSTHROUGH_EXCEPTIONS.delete(SystemExit)

# A more precise inspect method for Time improves assert failure messages.
#
class Time
  def inspect
    strftime("%a %b %d %H:%M:%S.#{format('%06d', usec)} %Z %Y")
  end
end
