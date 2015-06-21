class Nanoc::Int::RuleContextTest < Nanoc::TestCase
  def test_objects
    # Mock everything
    config = mock
    items = mock
    layouts = mock
    site = mock
    site.stubs(:config).returns(config)
    site.stubs(:items).returns(items)
    site.stubs(:layouts).returns(layouts)
    item = mock
    item.stubs(:site).returns(site)
    rep = mock
    rep.stubs(:item).returns(item)
    reps = mock

    # Create context
    executor = nil
    rule_context = Nanoc::Int::RuleContext.new(
      reps: reps, rep: rep, executor: executor, site: site)

    # Check classes
    assert_equal Nanoc::ItemRepView,          rule_context.rep.class
    assert_equal Nanoc::ItemView,             rule_context.item.class
    assert_equal Nanoc::SiteView,             rule_context.site.class
    assert_equal Nanoc::ConfigView,           rule_context.config.class
    assert_equal Nanoc::LayoutCollectionView, rule_context.layouts.class
    assert_equal Nanoc::ItemCollectionView,   rule_context.items.class

    # Check content
    assert_equal rep,     rule_context.rep.unwrap
    assert_equal item,    rule_context.item.unwrap
    assert_equal site,    rule_context.site.unwrap
    assert_equal config,  rule_context.config.unwrap
    assert_equal layouts, rule_context.layouts.unwrap
    assert_equal items,   rule_context.items.unwrap

    # Check reps
    assert_equal reps, rule_context.item.unwrap_reps
    assert_equal reps, rule_context.layouts.unwrap_reps
    assert_equal reps, rule_context.items.unwrap_reps
  end

  def test_actions
    # Mock everything
    config = mock
    items = mock
    layouts = mock
    site = mock
    site.stubs(:config).returns(config)
    site.stubs(:items).returns(items)
    site.stubs(:layouts).returns(layouts)
    item = mock
    item.stubs(:site).returns(site)
    reps = mock

    # Mock rep
    rep = mock
    rep.stubs(:item).returns(item)

    # Create context
    executor = nil
    rule_context = Nanoc::Int::RuleContext.new(
      reps: reps, rep: rep, executor: executor, site: site)

    # Check
    assert_raises(NoMethodError) do
      rule_context.instance_eval do
        item_rep.filter :foo, bar: 'baz'
      end
    end
    assert_raises(NoMethodError) do
      rule_context.instance_eval do
        item_rep.layout 'foo'
      end
    end
    assert_raises(NoMethodError) do
      rule_context.instance_eval do
        item_rep.snapshot 'awesome'
      end
    end
  end
end
