require 'test/helper'

class Nanoc::FilterTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize
    # Create filter
    filter = Nanoc::Filter.new

    # Test assigns
    assert_equal({}, filter.instance_eval { @assigns })
  end

  def test_assigns
    # Create filter
    filter = Nanoc::Filter.new({ :foo => 'bar' })

    # Check assigns
    assert_equal('bar', filter.assigns[:foo])
  end

  def test_run
    # Create filter
    filter = Nanoc::Filter.new

    # Make sure an error is raised
    assert_raises(NotImplementedError) do
      filter.run(nil)
    end
  end

end
