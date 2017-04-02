require 'helper'

class Nanoc::CLI::Commands::HelpTest < Nanoc::TestCase
  def test_run
    Nanoc::CLI.run %w[help]
    Nanoc::CLI.run %w[help co]
  end
end
