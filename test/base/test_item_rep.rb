require 'test/helper'

class Nanoc::ItemRepTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    # Mock site
    site = MiniTest::Mock.new
    site.expect(:pages, [])
    site.expect(:assets, [])
    site.expect(:config, [])
    site.expect(:layouts, [])

    # Mock item
    item = MiniTest::Mock.new
    item.expect(:content, %[<%= '<%= "blah" %' + '>' %>])
    item.expect(:site, site)

    # Create item rep
    item_rep = Nanoc::ItemRep.new(item, {}, '/foo/')
    # FIXME ugly
    item_rep.instance_eval do
      @content[:raw]  = item.content
      @content[:last] = @content[:raw]
    end

    # Filter once
    item_rep.filter!(:erb)
    # FIXME ugly
    assert_equal(%[<%= "blah" %>], item_rep.instance_eval { @content[:last] })

    # Filter twice
    item_rep.filter!(:erb)
    # FIXME ugly
    assert_equal(%[blah], item_rep.instance_eval { @content[:last] })
  end

  def test_layout
    # Mock layout
    layout = mock
    layout.stubs(:path).returns('/somelayout/')
    layout.stubs(:filter_class).returns(Nanoc::Filters::ERB)
    layout.stubs(:to_proxy).returns(nil)
    layout.stubs(:content).returns(%[<%= "blah" %>])

    # Mock site
    site = mock
    site.stubs(:pages).returns([])
    site.stubs(:assets).returns([])
    site.stubs(:config).returns([])
    site.stubs(:layouts).returns([ layout ])

    # Mock item
    item = mock
    item.stubs(:content).returns(%[Hello.])
    item.stubs(:site).returns(site)

    # Create item rep
    item_rep = Nanoc::ItemRep.new(item, {}, '/foo/')
    # FIXME ugly
    item_rep.instance_eval do
      @content[:raw]  = item.content
      @content[:last] = @content[:raw]
    end

    # Layout
    item_rep.layout!('/somelayout/')
    # FIXME ugly
    assert_equal(%[blah], item_rep.instance_eval { @content[:last] })
  end

end
