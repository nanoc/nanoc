# encoding: utf-8

class Nanoc::Helpers::LinkToTest < Nanoc::TestCase

  include Nanoc::Helpers::LinkTo

  def new_item_rep_with_path(path)
    item = Nanoc::Item.new('content', {}, '/')
    snapshot_store = Nanoc::SnapshotStore::InMemory.new
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => snapshot_store)
    rep.paths = { :last => path }
    rep
  end

  def teardown
    super
    @item     = nil
    @item_rep = nil
  end

  def test_link_to_with_path
    assert_equal(
      '<a href="/foo/">Foo</a>',
      link_to('Foo', '/foo/')
    )
  end

  def test_link_to_with_rep
    rep = new_item_rep_with_path('/bar/')
    assert_equal(
      '<a href="/bar/">Bar</a>',
      link_to('Bar', rep)
    )
  end

  def test_link_to_with_item
    rep = new_item_rep_with_path('/bar/')
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    item = Nanoc::ItemProxy.new(rep.item, item_rep_store)
    assert_equal(
      '<a href="/bar/">Bar</a>',
      link_to('Bar', item)
    )
  end

  def test_link_to_with_attributes
    assert_equal(
      '<a title="Dis mai foo!" href="/foo/">Foo</a>',
      link_to('Foo', '/foo/', :title => 'Dis mai foo!')
    )
  end

  def test_link_to_escape
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
    @item_rep = new_item_rep_with_path('/foo/')

    assert_equal(
      '<span class="active" title="You\'re here.">Bar</span>',
      link_to_unless_current('Bar', @item_rep)
    )
  end

  def test_link_to_unless_current_not_current
    @item_rep = new_item_rep_with_path('/foo/')

    assert_equal(
      '<a href="/abc/xyz/">Bar</a>',
      link_to_unless_current('Bar', '/abc/xyz/')
    )
  end

  def test_relative_path_to_with_self
    @item_rep = new_item_rep_with_path('/foo/bar/baz/')

    assert_equal(
      './',
      relative_path_to('/foo/bar/baz/')
    )
  end

  def test_relative_path_to_with_root
    @item_rep = new_item_rep_with_path('/foo/bar/baz/')

    assert_equal(
      '../../../',
      relative_path_to('/')
    )
  end

  def test_relative_path_to_file
    @item_rep = new_item_rep_with_path('/foo/bar/baz/')

    assert_equal(
      '../../quux',
      relative_path_to('/foo/quux')
    )
  end

  def test_relative_path_to_dir
    @item_rep = new_item_rep_with_path('/foo/bar/baz/')

    assert_equal(
      '../../quux/',
      relative_path_to('/foo/quux/')
    )
  end

  def test_relative_path_to_rep
    @item_rep = new_item_rep_with_path('/foo/bar/baz/')
    other_item_rep = new_item_rep_with_path('/foo/quux/')

    assert_equal(
      '../../quux/',
      relative_path_to(other_item_rep)
    )
  end


  def test_relative_path_to_item
    @item_rep = new_item_rep_with_path('/foo/bar/baz/')
    other_item_rep = new_item_rep_with_path('/foo/quux/')

    assert_equal(
      '../../quux/',
      relative_path_to(other_item_rep)
    )
  end

  def test_relative_path_to_to_nil
    @item_rep = new_item_rep_with_path(nil)
    other_item_rep = new_item_rep_with_path('/foo/quux/')

    assert_raises RuntimeError do
      relative_path_to(other_item_rep)
    end
  end

  def test_relative_path_to_from_nil
    @item_rep = new_item_rep_with_path('/foo/quux/')
    other_item_rep = new_item_rep_with_path(nil)

    assert_raises RuntimeError do
      relative_path_to(other_item_rep)
    end
  end

  def test_relative_path_to_to_windows_path
    @item_rep = new_item_rep_with_path('/foo/quux/')

    assert_equal '//mydomain/tahontaenrat', relative_path_to('//mydomain/tahontaenrat')
  end

  def test_examples_link_to
    # Parse
    YARD.parse(File.dirname(__FILE__) + '/../../lib/nanoc/helpers/link_to.rb')

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
    YARD.parse(File.dirname(__FILE__) + '/../../lib/nanoc/helpers/link_to.rb')

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
    YARD.parse(File.dirname(__FILE__) + '/../../lib/nanoc/helpers/link_to.rb')

    # Mock
    @item_rep = self.new_item_rep_with_path('/foo/bar/')

    # Run
    assert_examples_correct 'Nanoc::Helpers::LinkTo#relative_path_to'
  end

end
