# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

require 'nanoc'
require 'nanoc/cli'
require 'nanoc/spec'

require 'timecop'
require 'rspec/its'

Nanoc::CLI.setup

RSpec.configure do |c|
  c.around(:each) do |example|
    Nanoc::CLI::ErrorHandler.disable
    example.run
    Nanoc::CLI::ErrorHandler.enable
  end

  c.around(:each) do |example|
    Dir.mktmpdir('nanoc-test') do |dir|
      FileUtils.cd(dir) do
        example.run
      end
    end
  end

  c.around(:each, chdir: false) do |example|
    FileUtils.cd(File.dirname(__FILE__) + '/..') do
      example.run
    end
  end

  c.before(:each) do
    Nanoc::Int::NotificationCenter.reset
  end

  c.before(:each, v8: true) do
    if ENV.key?('DISABLE_V8')
      skip 'V8 specs are disabled (broken on Ruby 2.4)'
    end
  end

  c.around(:each, stdio: true) do |example|
    orig_stdout = $stdout
    orig_stderr = $stderr

    unless ENV['QUIET'] == 'false'
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    example.run

    $stdout = orig_stdout
    $stderr = orig_stderr
  end

  c.before(:each, site: true) do
    FileUtils.mkdir_p('content')
    FileUtils.mkdir_p('layouts')
    FileUtils.mkdir_p('lib')
    FileUtils.mkdir_p('output')

    File.write('nanoc.yaml', '{}')

    File.write('Rules', 'passthrough "/**/*"')
  end

  c.include(Nanoc::Spec::HelperHelper, helper: true)

  # Set focus if any
  if ENV.fetch('FOCUS', false)
    $stdout.puts "Focusing spec on '#{ENV['FOCUS']}'"
    c.filter_run_including ENV['FOCUS'].to_sym => true
  end
end

RSpec::Matchers.define_negated_matcher :not_match, :match

RSpec::Matchers.define :raise_frozen_error do |_expected|
  match do |actual|
    begin
      actual.call
      false
    rescue => e
      if e.is_a?(RuntimeError) || e.is_a?(TypeError)
        e.message =~ /(^can't modify frozen |^unable to modify frozen object$)/
      else
        false
      end
    end
  end

  supports_block_expectations

  failure_message do |_actual|
    'expected that proc would raise a frozen error'
  end

  failure_message_when_negated do |_actual|
    'expected that proc would not raise a frozen error'
  end
end

RSpec::Matchers.define :be_humanly_sorted do
  match do |actual|
    actual == sort(actual)
  end

  description do
    'be humanly sorted'
  end

  failure_message do |actual|
    expected_order = []
    actual.zip(sort(actual)).each do |a, b|
      if a != b
        expected_order << b
      end
    end

    "expected collection to be sorted (incorrect order: #{expected_order.join(' < ')})"
  end

  def sort(x)
    x.sort_by { |n| n.dup.unicode_normalize(:nfd).encode('ASCII', fallback: ->(_) { '' }).downcase }
  end
end

RSpec::Matchers.define :finish_in_under do |expected|
  supports_block_expectations

  match do |actual|
    before = Time.now
    actual.call
    after = Time.now
    @actual_duration = after - before
    @actual_duration < expected
  end

  chain :seconds do
  end

  failure_message do |_actual|
    "expected that proc would finish in under #{expected}s, but took #{format '%0.1fs', @actual_duration}"
  end

  failure_message_when_negated do |_actual|
    "expected that proc would not finish in under #{expected}s, but took #{format '%0.1fs', @actual_duration}"
  end
end

RSpec::Matchers.define :yield_from_fiber do |expected|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    @res = Fiber.new { actual.call }.resume
    values_match?(expected, @res)
  end

  description do
    "yield #{expected.inspect} from fiber"
  end

  failure_message do |_actual|
    "expected that proc would yield #{expected.inspect} from fiber, but was #{@res.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected that proc would not yield #{expected.inspect} from fiber, but was #{@res.inspect}"
  end
end

RSpec::Matchers.define :raise_wrapped_error do |expected|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    begin
      actual.call
    rescue Nanoc::Int::Errors::CompilationError => e
      values_match?(expected, e.unwrap)
    end
  end

  description do
    "raise wrapped error #{expected.inspect}"
  end

  failure_message do |_actual|
    "expected that proc would raise wrapped error #{expected.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected that proc would not raise wrapped error #{expected.inspect}"
  end
end

RSpec::Matchers.define :be_some_textual_content do |expected|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.is_a?(Nanoc::Int::TextualContent) && values_match?(expected, actual.string)
  end

  description do
    "textual content matching #{expected.inspect}"
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be textual content matching #{expected.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual.inspect} not to be textual content matching #{expected.inspect}"
  end
end

RSpec::Matchers.define :be_some_binary_content do |expected|
  include RSpec::Matchers::Composable

  match do |actual|
    actual.is_a?(Nanoc::Int::BinaryContent) && values_match?(expected, File.read(actual.filename))
  end

  description do
    "binary content matching #{expected.inspect}"
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be binary content matching #{expected.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual.inspect} not to be binary content matching #{expected.inspect}"
  end
end

RSpec::Matchers.alias_matcher :some_textual_content, :be_some_textual_content
RSpec::Matchers.alias_matcher :some_binary_content, :be_some_binary_content

RSpec::Matchers.define :send_notification do |name, *expected_args|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    @actual_notifications = []
    Nanoc::Int::NotificationCenter.on(name, self) do |*actual_args|
      @actual_notifications << actual_args
    end
    actual.call
    @actual_notifications.any? { |c| c == expected_args }
  end

  description do
    "send notification #{name.inspect} with args #{expected_args.inspect}"
  end

  failure_message do |_actual|
    s = "expected that proc would send notification #{name.inspect} with args #{expected_args.inspect}"
    if @actual_notifications.any?
      s << " (received #{@actual_notifications.size} times with other arguments: #{@actual_notifications.map(&:inspect).join(', ')})"
    end
    s
  end

  failure_message_when_negated do |_actual|
    "expected that proc would not send notification #{name.inspect} with args #{expected_args.inspect}"
  end
end
