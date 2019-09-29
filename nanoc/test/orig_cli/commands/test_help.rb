# frozen_string_literal: true

require 'helper'

class Nanoc::OrigCLI::Commands::HelpTest < Nanoc::TestCase
  def test_run
    Nanoc::OrigCLI.run %w[help]
    Nanoc::OrigCLI.run %w[help co]
  end
end
