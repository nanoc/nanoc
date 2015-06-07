$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
require 'nanoc'
require 'nanoc/cli'
Nanoc::CLI.setup

require 'fakefs/spec_helpers'

RSpec.configure do |c|
  c.include FakeFS::SpecHelpers

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
end

RSpec::Matchers.define :raise_frozen_error do |expected|
  match do |actual|
    begin
      actual.call
    rescue => e
      unless e.is_a?(RuntimeError) || e.is_a?(TypeError)
        false
      else
        e.message =~ /(^can't modify frozen |^unable to modify frozen object$)/
      end
    end
  end

  supports_block_expectations

  failure_message do |actual|
    'expected that proc would raise a frozen error'
  end

  failure_message_when_negated do |actual|
    'expected that proc would not raise a frozen error'
  end
end
