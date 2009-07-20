# encoding: utf-8

require 'test/helper'

class Nanoc3::RuleContextTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

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

    # Create context
    @rule_context = Nanoc3::RuleContext.new(rep)

    # Check
    assert_equal rep,     @rule_context.rep
    assert_equal item,    @rule_context.item
    assert_equal site,    @rule_context.site
    assert_equal config,  @rule_context.config
    assert_equal layouts, @rule_context.layouts
    assert_equal items,   @rule_context.items
  end

  def test_actions
    # Mock rep
    rep = mock
    rep.expects(:filter).with(:foo, { :bar => 'baz' })
    rep.expects(:layout).with('foo')
    rep.expects(:snapshot).with('awesome')

    # Create context
    @rule_context = Nanoc3::RuleContext.new(rep)

    # Check
    rep.filter   :foo, :bar => 'baz'
    rep.layout   'foo'
    rep.snapshot 'awesome'
  end

end
