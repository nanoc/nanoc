# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemCommonTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  class TestDataSource
    include Nanoc3::DataSources::FilesystemCommon
  end

  def test_code
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCommonTest::TestDataSource.new

    # Create code
    FileUtils.mkdir_p('lib')
    File.open('lib/foo.rb', 'w') do |io|
      io.write("# This is a bit of code right here...\n")
    end

    # Load code
    code = data_source.code

    # Check code
    assert_equal(
      [ { :code => "# This is a bit of code right here...\n", :filename => 'lib/foo.rb' } ],
      code.snippets
    )
  end

  def test_rules_with_valid_rules_file_names
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCommonTest::TestDataSource.new

    [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].each do |filename|
      begin
        # Create a sample rules file
        File.open(filename, 'w') { |io| io.write("This is #{filename}.") }
        
        # Attempt to read it
        assert_equal "This is #{filename}.", data_source.rules[0]
        assert_equal File.stat(filename).mtime, data_source.rules[1]
      ensure
        FileUtils.rm(filename)
      end
    end
  end

  def test_rules_with_invalid_rules_file_names
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil)

    begin
      # Create a sample rules file
      File.open('ZeRules', 'w') { |io| io.write("This is a rules file with an invalid name.") }

      # Attempt to read it
      assert_raises(Nanoc3::Errors::NoRulesFileFound) do
        data_source.rules
      end
    ensure
      FileUtils.rm('ZeRules')
    end
  end

end
