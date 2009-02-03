require 'test/helper'

class Nanoc::FilterTest < Test::Unit::TestCase

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
    assert_raise(NotImplementedError) do
      filter.run(nil)
    end
  end

  def test_extensions
    # Create filter
    filter = Nanoc::Filter.new

    # Update extension
    filter.class.class_eval { extension :foo }

    # Check
    assert_equal(:foo, filter.class.class_eval { extension })
    assert_equal([ :foo ], filter.class.class_eval { extensions })

    # Update extension
    filter.class.class_eval { extensions :foo, :bar }

    # Check
    assert_equal([ :foo, :bar ], filter.class.class_eval { extensions })
  end

end
