require 'test/helper'

class Nanoc::EnhancementsTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_in_dir
    # Initialize
    current_dir = Dir.getwd

    # Go into a lower dir
    in_dir([ 'lib' ]) do
      assert_equal(File.join([ current_dir, 'lib' ]), Dir.getwd)
    end
  end

end
