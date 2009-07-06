# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemCommonTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  class TestDataSource
    include Nanoc3::DataSources::FilesystemCommon
  end

  def test_code_snippets
    # Create data source
    data_source = Nanoc3::DataSources::FilesystemCommonTest::TestDataSource.new

    # Create code
    FileUtils.mkdir_p('lib')
    File.open('lib/foo.rb', 'w') { |io| io.write("# Foo code here...\n") }
    File.open('lib/bar.rb', 'w') { |io| io.write("# Bar code here...\n") }

    # Load code
    code_snippets = data_source.code_snippets

    # Check code
    assert code_snippets.any? { |cs| cs.filename == 'foo.rb' && cs.data == "# Foo code here...\n" }
    assert code_snippets.any? { |cs| cs.filename == 'bar.rb' && cs.data == "# Bar code here...\n" }
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
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil)

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
