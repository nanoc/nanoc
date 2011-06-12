# encoding: utf-8

class Nanoc3::CLI::BaseTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  COMMAND_CODE = <<EOS
# encoding: utf-8

module Nanoc3::CLI::Commands

  class ExampleCommandUsedForTesting < ::Nanoc3::CLI::Command

    def name
      '_test'
    end

    def aliases
      []
    end

    def short_desc
      'meh'
    end

    def long_desc
      'longer meh'
    end

    def usage
      "nanoc3 _test"
    end

    def run(options, arguments)
      File.open('_test.out', 'w') { |io| io.write('It works!') }
    end

  end

end
EOS

  def test_load_custom_commands
    Nanoc3::CLI::Base.shared_base.run([ 'create_site', 'foo' ])

    FileUtils.cd('foo') do
      # Create command
      FileUtils.mkdir_p('lib/commands')
      File.open('lib/commands/whatever.rb', 'w') { |io| io.write(COMMAND_CODE) }

      # Run command
      begin
        Nanoc3::CLI::Base.shared_base.run([ '_test' ])
      rescue SystemExit
        assert false, 'Running _test should not cause system exit'
      end

      # Check
      assert File.file?('_test.out')
      assert_equal 'It works!', File.read('_test.out')
    end
  end

end
