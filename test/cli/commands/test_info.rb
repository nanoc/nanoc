# encoding: utf-8

class Nanoc::CLI::Commands::InfoTest < Nanoc::TestCase

  def test_run
    Nanoc::CLI.run %w( info )
  end

end
