# encoding: utf-8

class Nanoc::CLI::Commands::CleanStraysTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run
    with_site do |site|
      FileUtils.mkdir_p('output')
      File.open('output/foo.html', 'w') { |io| io.write 'this is a foo.' }
      assert File.file?('output/foo.html')
      Nanoc::CLI.run %w( clean_strays )
      assert !File.file?('output/foo.html')
    end
  end

end
