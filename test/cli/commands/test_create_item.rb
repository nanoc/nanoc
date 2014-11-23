# encoding: utf-8

class Nanoc::CLI::Commands::CreateItemTest < Nanoc::TestCase
  def test_run
    with_site do |_site|
      Nanoc::CLI.run %w( create_item /blah/ )
      assert File.file?('content/blah.html')
    end
  end
end
