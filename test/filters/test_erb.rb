require 'test/helper'

class Nanoc::Filters::ERBTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_nothing_raised do
      # Create filter
      filter = ::Nanoc::Filters::ERB.new({ :location => 'a cheap motel' })

      # Run filter
      result = filter.run('<%= "I was hiding in #{@location}." %>')
      assert_equal('I was hiding in a cheap motel.', result)
    end
  end

end
