# encoding: utf-8

class Nanoc3::CLI::Commands::InfoTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_run
    Nanoc3::CLI.run %w( info )
  end

end
