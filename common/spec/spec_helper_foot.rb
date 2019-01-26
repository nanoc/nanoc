# frozen_string_literal: true

require_relative 'spec_helper_foot_core'

Nanoc::CLI.setup

RSpec.configure do |c|
  c.include(Nanoc::Spec::Helper)

  c.include(Nanoc::Spec::HelperHelper, helper: true)

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

  c.around(:each) do |example|
    Nanoc::CLI::ErrorHandler.disable
    example.run
    Nanoc::CLI::ErrorHandler.enable
  end

  c.before(:each) do
    Nanoc::Int::NotificationCenter.reset
  end

  c.before(:each, fork: true) do
    skip 'fork() is not supported on Windows' if Nanoc.on_windows?
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
    Nanoc::Int::NotificationCenter.sync

    @actual_notifications.any? { |c| c == expected_args }
  end

  description do
    "send notification #{name.inspect} with args #{expected_args.inspect}"
  end

  failure_message do |_actual|
    s = +"expected that proc would send notification #{name.inspect} with args #{expected_args.inspect}"
    if @actual_notifications.any?
      s << " (received #{@actual_notifications.size} times with other arguments: #{@actual_notifications.map(&:inspect).join(', ')})"
    end
    s
  end

  failure_message_when_negated do |_actual|
    "expected that proc would not send notification #{name.inspect} with args #{expected_args.inspect}"
  end
end

RSpec::Matchers.define :create_dependency_on do |expected|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    @to = expected
    dependency_tracker = @to._context.dependency_tracker
    dependency_store = dependency_tracker.dependency_store

    from = Nanoc::Core::Item.new('x', {}, '/x.md')

    a = dependency_store.objects_causing_outdatedness_of(from)

    begin
      dependency_tracker.enter(from)
      actual.call
    ensure
      dependency_tracker.exit
    end

    b = dependency_store.objects_causing_outdatedness_of(from)

    (b - a).include?(@to)
  end

  description do
    "create a dependency onto #{expected.inspect}"
  end

  failure_message do |_actual|
    "expected dependency to be created onto #{expected.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected no dependency to be created onto #{expected.inspect}"
  end
end

RSpec::Matchers.define :create_dependency_from do |expected|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    @from = expected
    dependency_tracker = @from._context.dependency_tracker
    dependency_store = dependency_tracker.dependency_store

    a = dependency_store.objects_causing_outdatedness_of(@from)

    begin
      dependency_tracker.enter(@from._unwrap)
      actual.call
    ensure
      dependency_tracker.exit
    end

    b = dependency_store.objects_causing_outdatedness_of(@from)

    @actual = b - a

    if @onto
      values_match?(@onto, @actual)
    else
      @actual.any?
    end
  end

  chain :onto do |onto|
    @onto = onto
  end

  description do
    "create a dependency from #{expected.inspect}"
  end

  failure_message do |_actual|
    "expected a dependency to be created from #{expected.inspect}#{@onto ? " onto #{@onto.inspect}" : nil}, but generated #{@actual.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected no dependency to be created from #{expected.inspect}, but generated #{@actual.inspect}"
  end
end
