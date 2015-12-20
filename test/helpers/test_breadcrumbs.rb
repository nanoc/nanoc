class Nanoc::Helpers::BreadcrumbsTest < Nanoc::TestCase
  include Nanoc::Helpers::Breadcrumbs

  def test_breadcrumbs_trail_at_root
    @items = Nanoc::Int::IdentifiableCollection.new({})
    item = Nanoc::Int::Item.new('root', {}, Nanoc::Identifier.new('/', type: :legacy))
    @items << item
    @item = item

    assert_equal [item], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_1_parent
    @items = Nanoc::Int::IdentifiableCollection.new({})
    parent_item = Nanoc::Int::Item.new('parent', {}, Nanoc::Identifier.new('/', type: :legacy))
    child_item  = Nanoc::Int::Item.new('child',  {}, Nanoc::Identifier.new('/foo/', type: :legacy))
    @items << parent_item
    @items << child_item
    @item = child_item

    assert_equal [parent_item, child_item], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_many_parents
    @items = Nanoc::Int::IdentifiableCollection.new({})
    grandparent_item = Nanoc::Int::Item.new('grandparent', {}, Nanoc::Identifier.new('/', type: :legacy))
    parent_item      = Nanoc::Int::Item.new('parent',      {}, Nanoc::Identifier.new('/foo/', type: :legacy))
    child_item       = Nanoc::Int::Item.new('child',       {}, Nanoc::Identifier.new('/foo/bar/', type: :legacy))
    @items << grandparent_item
    @items << parent_item
    @items << child_item
    @item = child_item

    assert_equal [grandparent_item, parent_item, child_item], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_nils
    @items = Nanoc::Int::IdentifiableCollection.new({})
    grandparent_item = Nanoc::Int::Item.new('grandparent', {}, Nanoc::Identifier.new('/', type: :legacy))
    child_item       = Nanoc::Int::Item.new('child',       {}, Nanoc::Identifier.new('/foo/bar/', type: :legacy))
    @items << grandparent_item
    @items << child_item
    @item = child_item

    assert_equal [grandparent_item, nil, child_item], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_non_legacy_identifiers
    @items = Nanoc::Int::IdentifiableCollection.new({})
    parent_item = Nanoc::Int::Item.new('parent', {}, '/')
    child_item  = Nanoc::Int::Item.new('child',  {}, '/foo/')
    @items << parent_item
    @items << child_item
    @item = child_item

    assert_raises Nanoc::Helpers::Breadcrumbs::CannotGetBreadcrumbsForNonLegacyItem do
      breadcrumbs_trail
    end
  end
end
