# encoding: utf-8

class Nanoc3::CLITest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  COMMAND_CODE = <<EOS
# encoding: utf-8

usage       '_test [options]'
summary     'meh'
description 'longer meh'

run do |opts, args, cmd|
  File.open('_test.out', 'w') { |io| io.write('It works!') }
end
EOS

  def test_load_custom_commands
    Nanoc3::CLI.run %w( create_site foo )

    FileUtils.cd('foo') do
      # Create command
      FileUtils.mkdir_p('lib/commands')
      File.open('lib/commands/_test.rb', 'w') { |io| io.write(COMMAND_CODE) }

      # Run command
      begin
        Nanoc3::CLI.run %w( _test )
      rescue SystemExit
        assert false, 'Running _test should not cause system exit'
      end

      # Check
      assert File.file?('_test.out')
      assert_equal 'It works!', File.read('_test.out')
    end
  end

end
