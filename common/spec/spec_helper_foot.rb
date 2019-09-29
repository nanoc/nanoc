# frozen_string_literal: true

require_relative 'spec_helper_foot_core'

Nanoc::OrigCLI.setup

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

  c.around do |example|
    Nanoc::OrigCLI::ErrorHandler.disable
    example.run
    Nanoc::OrigCLI::ErrorHandler.enable
  end

  c.before(:each, fork: true) do
    skip 'fork() is not supported on Windows' if Nanoc::Core.on_windows?
  end
end

RSpec::Matchers.define :raise_wrapped_error do |expected|
  supports_block_expectations

  include RSpec::Matchers::Composable

  match do |actual|
    begin
      actual.call
    rescue Nanoc::Core::Errors::CompilationError => e
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
