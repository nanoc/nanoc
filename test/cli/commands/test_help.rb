# encoding: utf-8

class Nanoc3::CLI::Commands::HelpTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  def test_run
    Nanoc3::CLI.run %w( help )
    Nanoc3::CLI.run %w( help co )
  end

end
