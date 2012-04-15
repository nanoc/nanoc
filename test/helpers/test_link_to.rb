# encoding: utf-8

class Nanoc::Helpers::LinkToTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::LinkTo

  def test_link_to_with_path
    # Check
    assert_equal(
      '<a href="/foo/">Foo</a>',
      link_to('Foo', '/foo/')
    )
  end

  def test_link_to_with_rep
    # Create rep
    rep = mock
    rep.stubs(:path).returns('/bar/')

    # Check
    assert_equal(
      '<a href="/bar/">Bar</a>',
      link_to('Bar', rep)
    )
  end

  def test_link_to_with_item
    # Create rep
    item = mock
    item.stubs(:path).returns('/bar/')

    # Check
    assert_equal(
      '<a href="/bar/">Bar</a>',
      link_to('Bar', item)
    )
  end

  def test_link_to_with_attributes
    # Check
    assert_equal(
      '<a title="Dis mai foo!" href="/foo/">Foo</a>',
      link_to('Foo', '/foo/', :title => 'Dis mai foo!')
    )
  end

  def test_link_to_escape
    # Check
    assert_equal(
      '<a title="Foo &amp; Bar" href="/foo&amp;bar/">Foo &amp; Bar</a>',
      link_to('Foo &amp; Bar', '/foo&bar/', :title => 'Foo & Bar')
    )
  end

  def test_link_to_to_nil_item_or_item_rep
    obj = Object.new
    def obj.path ; nil ; end

    assert_raises RuntimeError do
      link_to("Some Text", obj)
    end
  end

  def test_link_to_unless_current_current
    # Create item
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/')

    # Check
    assert_equal(
      '<span class="active" title="You\'re here.">Bar</span>',
      link_to_unless_current('Bar', @item_rep)
    )
  ensure
    @item = nil
  end

  def test_link_to_unless_current_not_current
    # Create item
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/')

    # Check
    assert_equal(
      '<a href="/abc/xyz/">Bar</a>',
      link_to_unless_current('Bar', '/abc/xyz/')
    )
  end

  def test_relative_path_to_with_self
    # Mock item
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/baz/')

    # Test
    assert_equal(
      './',
      relative_path_to('/foo/bar/baz/')
    )
  end

  def test_relative_path_to_with_root
    # Mock item
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/baz/')

    # Test
    assert_equal(
      '../../../',
      relative_path_to('/')
    )
  end

  def test_relative_path_to_file
    # Mock item
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/baz/')

    # Test
    assert_equal(
      '../../quux',
      relative_path_to('/foo/quux')
    )
  end

  def test_relative_path_to_dir
    # Mock item
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/baz/')

    # Test
    assert_equal(
      '../../quux/',
      relative_path_to('/foo/quux/')
    )
  end

  def test_relative_path_to_rep
    # Mock self
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/baz/')

    # Mock other
    other_item_rep = mock
    other_item_rep.stubs(:path).returns('/foo/quux/')

    # Test
    assert_equal(
      '../../quux/',
      relative_path_to(other_item_rep)
    )
  end


  def test_relative_path_to_item
    # Mock self
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/baz/')

    # Mock other
    other_item = mock
    other_item.stubs(:path).returns('/foo/quux/')

    # Test
    assert_equal(
      '../../quux/',
      relative_path_to(other_item)
    )
  end

  def test_relative_path_to_to_nil
    # Mock self
    @item_rep = mock
    @item_rep.stubs(:path).returns(nil)

    # Mock other
    other_item_rep = mock
    other_item_rep.stubs(:path).returns('/foo/quux/')

    # Test
    assert_raises RuntimeError do
      relative_path_to(other_item_rep)
    end
  end

  def test_relative_path_to_from_nil
    # Mock self
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/quux/')

    # Mock other
    other_item_rep = mock
    other_item_rep.stubs(:path).returns(nil)

    # Test
    assert_raises RuntimeError do
      relative_path_to(other_item_rep)
    end
  end

  def test_relative_path_to_to_windows_path
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/quux/')

    assert_equal '//mydomain/tahontaenrat', relative_path_to('//mydomain/tahontaenrat')
  end

  def test_examples_link_to
    # Parse
    YARD.parse('../lib/nanoc/helpers/link_to.rb')

    # Mock
    @items = [ mock, mock, mock ]
    @items[0].stubs(:identifier).returns('/about/')
    @items[0].stubs(:path).returns('/about.html')
    @items[1].stubs(:identifier).returns('/software/')
    @items[1].stubs(:path).returns('/software.html')
    @items[2].stubs(:identifier).returns('/software/nanoc/')
    @items[2].stubs(:path).returns('/software/nanoc.html')
    about_rep_vcard = mock
    about_rep_vcard.stubs(:path).returns('/about.vcf')
    @items[0].stubs(:rep).with(:vcard).returns(about_rep_vcard)

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#link_to'
  end

  def test_examples_link_to_unless_current
    # Parse
    YARD.parse('../lib/nanoc/helpers/link_to.rb')

    # Mock
    @item_rep = mock
    @item_rep.stubs(:path).returns('/about/')
    @item = mock
    @item.stubs(:path).returns(@item_rep.path)

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#link_to_unless_current'
  end

  def test_examples_relative_path_to
    # Parse
    YARD.parse('../lib/nanoc/helpers/link_to.rb')

    # Mock
    @item_rep = mock
    @item_rep.stubs(:path).returns('/foo/bar/')

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#relative_path_to'
  end

end
