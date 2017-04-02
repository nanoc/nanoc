require 'helper'

class Nanoc::CLI::Commands::CheckTest < Nanoc::TestCase
  def test_check_stale
    with_site do |_site|
      FileUtils.mkdir_p('output')

      # Should not raise now
      Nanoc::CLI.run %w[check stale]

      # Should raise now
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }
      assert_raises Nanoc::Int::Errors::GenericTrivial do
        Nanoc::CLI.run %w[check stale]
      end
    end
  end
end
