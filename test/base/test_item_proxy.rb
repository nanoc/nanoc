# encoding: utf-8

class Nanoc::ItemProxyTest < Nanoc::TestCase

  def setup
    super

    @snapshot_store = Nanoc::SnapshotStore::SQLite3.new
    @content = Nanoc::TextualContent.new('blah blah blah', File.absolute_path('content/somefile.md'))
    @item = Nanoc::Item.new(@content, {}, '/index.md')
    @rep_1 = Nanoc::ItemRep.new(@item, :default, :snapshot_store => @snapshot_store)
    @rep_2 = Nanoc::ItemRep.new(@item, :foo,     :snapshot_store => @snapshot_store)
    def @rep_1.compiled_content(params={}) ; "default content at #{params[:snapshot].inspect}" ; end
    def @rep_2.compiled_content(params={}) ; "foo content at #{params[:snapshot].inspect}" ; end
    def @rep_1.path(params={}) ; "default path at #{params[:snapshot].inspect}" ; end
    def @rep_2.path(params={}) ; "foo path at #{params[:snapshot].inspect}" ; end
    @item_rep_store = Nanoc::ItemRepStore.new([ @rep_1, @rep_2 ])
    @item_proxy = Nanoc::ItemProxy.new(@item, @item_rep_store)
  end

  def test_compiled_content_with_default_rep_and_default_snapshot
    assert_equal 'default content at nil', @item_proxy.compiled_content
  end

  def test_compiled_content_with_custom_rep_and_default_snapshot
    assert_equal 'foo content at nil', @item_proxy.compiled_content(:rep => :foo)
  end

  def test_compiled_content_with_default_rep_and_custom_snapshot
    assert_equal 'default content at :blah', @item_proxy.compiled_content(:snapshot => :blah)
  end

  def test_compiled_content_with_custom_nonexistant_rep
    assert_raises(Nanoc::Errors::Generic) do
      @item_proxy.compiled_content(:rep => :lkasdhflahgwfe)
    end
  end

  def test_path_with_default_rep
    assert_equal 'default path at nil', @item_proxy.path
  end

  def test_path_with_custom_rep
    assert_equal 'foo path at nil', @item_proxy.path(:rep => :foo)
  end

  def test_path_with_custom_nonexistant_rep
    assert_raises(Nanoc::Errors::Generic) do
      assert_equal 'foo path at nil', @item_proxy.path(:rep => :sdfklgh)
    end
  end

end
