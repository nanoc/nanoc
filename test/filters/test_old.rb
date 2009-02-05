require 'test/helper'

class Nanoc::Filters::OldTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_raises(Nanoc::Error) do
      # Create filter
      filter = ::Nanoc::Filters::Old.new

      # Run filter
      result = filter.run("blah")
    end
  end

end
