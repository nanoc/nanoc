# encoding: utf-8

class Nanoc::CLI::Commands::HelpTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  def test_run
    Nanoc::CLI.run %w( help )
    Nanoc::CLI.run %w( help co )
  end

end
