# encoding: utf-8

class Nanoc::CLI::Commands::CheckTest < Nanoc::TestCase

  def test_check_stale
    in_site do
      FileUtils.mkdir_p('output')

      # Should not raise now
      Nanoc::CLI.run %w( check stale )

      # Should raise now
      File.open('output/blah.html', 'w') { |io| io.write 'moo' }
      assert_raises Nanoc::Errors::GenericTrivial do
        Nanoc::CLI.run %w( check stale )
      end
    end
  end

end
