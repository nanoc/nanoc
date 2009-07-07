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

end
