# frozen_string_literal: true

$VERBOSE = false

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'mocha/minitest'
require 'vcr'

require 'debug'
require 'tmpdir'
require 'stringio'
require 'yard'

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

require 'nanoc'
require 'nanoc/orig_cli'

Nanoc::CLI.setup

module Nanoc
  module TestHelpers
    LIB_DIR = File.expand_path("#{__dir__}/../lib")

    def disable_nokogiri?
      ENV.key?('DISABLE_NOKOGIRI')
    end

    def if_have(*libs)
      libs.each do |lib|
        if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby' && lib == 'nokogiri' && disable_nokogiri?
          skip 'Pure Java Nokogiri has issues that cause problems with Nanoc (see https://github.com/nanoc/nanoc/pull/422) -- run without DISABLE_NOKOGIRI to enable Nokogiri tests'
        end

        begin
          require lib
        rescue LoadError
          skip "requiring #{lib} failed"
        end
      end

      yield
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
            File.write('layouts/default.html', '... <%= @yield %> ...')
          end

          File.open('nanoc.yaml', 'w') do |io|
            io << 'string_pattern_type: legacy' << "\n" if params.fetch(:legacy, true)
            io << 'data_sources:' << "\n"
            io << '  -' << "\n"
            io << '    type: filesystem' << "\n"
            io << '    identifier_type: legacy' << "\n" if params.fetch(:legacy, true)
          end

          File.write('Rules', rules_content)
        end
      end

      # Yield site
      FileUtils.cd(site_name) do
        site = Nanoc::Core::SiteLoader.new.new_from_cwd
        return yield(site)
      end
    end

    def setup
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

    def capturing_stdio(&)
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

    # Adapted from https://github.com/lsegal/yard-examples/tree/master/doctest
    def assert_examples_correct(object)
      P(object).tags(:example).each do |example|
        # Classify
        lines = example.text.lines.map do |line|
          [/^\s*# ?=>/.match?(line) ? :result : :code, line]
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

    def command?(cmd)
      TTY::Which.exist?(cmd)
    end

    def symlinks_supported?
      File.symlink nil, nil
    rescue NotImplementedError
      false
    rescue
      true
    end

    def skip_unless_have_command(cmd)
      skip "Could not find external command \"#{cmd}\"" unless command?(cmd)
    end

    def skip_unless_symlinks_supported
      skip 'Symlinks are not supported by Ruby on Windows' unless symlinks_supported?
    end

    def root_dir
      File.absolute_path("#{__dir__}/..")
    end

    # FIXME: deduplicate
    def path_to_file_uri(path, dir)
      output_dir = dir.is_a?(String) ? dir : dir.config.output_dir
      output_dir += '/' unless output_dir.end_with?('/')

      uri = Addressable::URI.convert_path(output_dir) + Addressable::URI.convert_path(path)
      uri.to_s
    end
  end
end

module Nanoc
  class TestCase < Minitest::Test
    include Nanoc::TestHelpers
  end
end

# Unexpected system exit is unexpected
Minitest::Test::PASSTHROUGH_EXCEPTIONS.delete(SystemExit)

# A more precise inspect method for Time improves assert failure messages.
#
class Time
  def inspect
    strftime("%a %b %d %H:%M:%S.#{format('%06d', usec)} %Z %Y")
  end
end
