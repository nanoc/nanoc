require 'test/helper'

class Nanoc::Filters::OldTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_raise(Nanoc::Error) do
      # Create filter
      filter = ::Nanoc::Filters::Old.new

      # Run filter
      result = filter.run("blah")
    end
  end

end
