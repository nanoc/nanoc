# encoding: utf-8

class Nanoc::CLI::Commands::InfoTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run
    Nanoc::CLI.run %w( info )
  end

end
