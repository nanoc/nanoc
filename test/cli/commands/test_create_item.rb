# encoding: utf-8

class Nanoc3::CLI::Commands::CreateItemTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_run
    with_site do |site|
      Nanoc3::CLI.run %w( create_item /blah/ )
      assert File.file?('content/blah.html')
    end
  end

end
