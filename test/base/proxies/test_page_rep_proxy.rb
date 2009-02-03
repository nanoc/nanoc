require 'test/helper'

class Nanoc::PageRepProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_get
    # Get page
    page = mock
    page.expects(:attribute_named).with(:moo).returns('page attr moo')

    # Get page proxy
    page_proxy = Nanoc::PageProxy.new(page)
    page.expects(:to_proxy).returns(page_proxy)

    # Get page rep
    page_rep = mock
    page_rep.expects(:name).returns('page rep name')
    page_rep.expects(:page).returns(page)
    page_rep.expects(:content).returns('page rep content')
    page_rep.expects(:web_path).returns('page rep web path')
    page_rep.expects(:attribute_named).times(2).with(:blah).returns('page rep attr blah')
    page_rep.expects(:attribute_named).with(:'blah!').returns('page rep attr blah!')

    # Get page proxy
    page_rep_proxy = Nanoc::PageRepProxy.new(page_rep)

    # Test
    assert_equal('page rep name',         page_rep_proxy.name)
    assert_equal('page rep content',      page_rep_proxy.content)
    assert_equal('page attr moo',         page_rep_proxy.page.moo)
    assert_equal('page rep web path',     page_rep_proxy.path)
    assert_equal('page rep attr blah',    page_rep_proxy.blah)
    assert_equal('page rep attr blah',    page_rep_proxy.blah?)
    assert_equal('page rep attr blah!',   page_rep_proxy.blah!)
  end

end
