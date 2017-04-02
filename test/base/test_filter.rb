require 'helper'

class Nanoc::FilterTest < Nanoc::TestCase
  def test_initialize
    # Create filter
    filter = Nanoc::Filter.new

    # Test assigns
    assert_equal({}, filter.instance_eval { @assigns })
  end

  def test_assigns_with_instance_variables
    # Create filter
    filter = Nanoc::Filter.new(foo: 'bar')

    # Check assigns
    assert_equal('bar', filter.instance_eval { @foo })
  end

  def test_assigns_with_instance_methods
    # Create filter
    filter = Nanoc::Filter.new(foo: 'bar')

    # Check assigns
    assert_equal('bar', filter.instance_eval { foo })
  end

  def test_run
    # Create filter
    filter = Nanoc::Filter.new

    # Make sure an error is raised
    assert_raises(NotImplementedError) do
      filter.run(nil)
    end
  end

  def test_filename_item
    # Mock items
    item = mock
    item.expects(:identifier).returns('/foo/bar/baz/')
    item_rep = mock
    item_rep.expects(:name).returns(:quux)

    # Create filter
    filter = Nanoc::Filter.new(item: item, item_rep: item_rep)

    # Check filename
    assert_equal('item /foo/bar/baz/ (rep quux)', filter.filename)
  end

  def test_filename_layout
    # Mock items
    layout = mock
    layout.expects(:identifier).returns('/wohba/')

    # Create filter
    filter = Nanoc::Filter.new(item: mock, item_rep: mock, layout: layout)

    # Check filename
    assert_equal('layout /wohba/', filter.filename)
  end

  def test_filename_unknown
    # Create filter
    filter = Nanoc::Filter.new({})

    # Check filename
    assert_equal('?', filter.filename)
  end
end
