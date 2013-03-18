# encoding: utf-8

class Nanoc::Helpers::BreadcrumbsTest < Nanoc::TestCase

  include Nanoc::Helpers::Breadcrumbs

  def test_breadcrumbs_trail_at_root
    @items = Nanoc::ItemArray.new
    @items << Nanoc::Item.new("root", {}, '/')
    @item = @items.last

    assert_equal [ @items[0] ], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_1_parent
    @items = Nanoc::ItemArray.new
    @items << Nanoc::Item.new("parent", {}, '/')
    @items << Nanoc::Item.new("child",  {}, '/foo/')
    @item = @items.last

    assert_equal [ @items[0], @items[1] ], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_many_parents
    @items = Nanoc::ItemArray.new
    @items << Nanoc::Item.new("grandparent", {}, '/')
    @items << Nanoc::Item.new("parent",      {}, '/foo/')
    @items << Nanoc::Item.new("child",       {}, '/foo/bar/')
    @item = @items.last

    assert_equal [ @items[0], @items[1], @items[2] ], breadcrumbs_trail
  end

  def test_breadcrumbs_trail_with_nils
    @items = Nanoc::ItemArray.new
    @items << Nanoc::Item.new("grandparent", {}, '/')
    @items << Nanoc::Item.new("child",       {}, '/foo/bar/')
    @item = @items.last

    assert_equal [ @items[0], nil, @items[1] ], breadcrumbs_trail
  end

end
