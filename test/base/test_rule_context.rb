# encoding: utf-8

class Nanoc::RuleContextTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

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
    compiler = Nanoc::Compiler.new(site)

    # Create context
    @rule_context = Nanoc::RuleContext.new(:rep => rep, :compiler => compiler)

    # Check
    assert_equal rep,     @rule_context.rep
    assert_equal item,    @rule_context.item
    assert_equal site,    @rule_context.site
    assert_equal config,  @rule_context.config
    assert_equal layouts, @rule_context.layouts
    assert_equal items,   @rule_context.items
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

    # Mock rep
    rep = mock
    rep.stubs(:item).returns(item)
    rep.expects(:filter).with(:foo, { :bar => 'baz' })
    rep.expects(:layout).with('foo')
    rep.expects(:snapshot).with('awesome')

    # Mock compiler
    compiler = Nanoc::Compiler.new(site)

    # Create context
    @rule_context = Nanoc::RuleContext.new(:rep => rep, :compiler => compiler)

    # Check
    rep.filter   :foo, :bar => 'baz'
    rep.layout   'foo'
    rep.snapshot 'awesome'
  end

end
