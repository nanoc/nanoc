class Nanoc::Helpers::BreadcrumbsTest < Nanoc::TestCase
  include Nanoc::Helpers::Breadcrumbs

  def test_breadcrumbs_trail_at_root
    @items = Nanoc::Int::IdentifiableCollection.new({})
    item = Nanoc::Int::Item.new('root', {}, '/')
    @items << item
    @item = item

    assert_equal [item], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_1_parent
    @items = Nanoc::Int::IdentifiableCollection.new({})
    parent_item = Nanoc::Int::Item.new('parent', {}, '/')
    child_item  = Nanoc::Int::Item.new('child',  {}, '/foo/')
    @items << parent_item
    @items << child_item
    @item = child_item

    assert_equal [parent_item, child_item], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_many_parents
    @items = Nanoc::Int::IdentifiableCollection.new({})
    grandparent_item = Nanoc::Int::Item.new('grandparent', {}, '/')
    parent_item      = Nanoc::Int::Item.new('parent',      {}, '/foo/')
    child_item       = Nanoc::Int::Item.new('child',       {}, '/foo/bar/')
    @items << grandparent_item
    @items << parent_item
    @items << child_item
    @item = child_item

    assert_equal [grandparent_item, parent_item, child_item], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_nils
    @items = Nanoc::Int::IdentifiableCollection.new({})
    grandparent_item = Nanoc::Int::Item.new('grandparent', {}, '/')
    child_item       = Nanoc::Int::Item.new('child',       {}, '/foo/bar/')
    @items << grandparent_item
    @items << child_item
    @item = child_item

    assert_equal [grandparent_item, nil, child_item], breadcrumbs_trail
  end
end
