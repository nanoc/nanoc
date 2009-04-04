require 'test/helper'

class Nanoc::PageProxyTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_get
    # Get page rep
    page_rep = mock
    page_rep.expects(:name).returns(:default)
    page_rep.expects(:web_path).returns('page rep web path')

    # Get page
    page = mock
    page.expects(:reps).returns([ page_rep ])
    page.expects(:mtime).returns(Time.parse('2008-05-19'))
    page.expects(:attribute_named).times(2).with(:blah).returns('page attr blah')
    page.expects(:attribute_named).with(:'blah!').returns('page attr blah!')

    # Get page proxy
    page_proxy = Nanoc::PageProxy.new(page)

    # Test
    assert_equal('page rep web path',       page_proxy.path)
    assert_equal(Time.parse('2008-05-19'),  page_proxy.mtime)
    assert_equal('page attr blah',          page_proxy.blah)
    assert_equal('page attr blah',          page_proxy.blah?)
    assert_equal('page attr blah!',         page_proxy.blah!)
  end

  def test_reps
    # Get page reps
    page_rep_0 = mock
    page_rep_0.expects(:name).at_least_once.returns(:default)
    page_rep_0.expects(:attribute_named).with(:foo).returns('bar')
    page_rep_1 = mock
    page_rep_1.expects(:name).at_least_once.returns(:raw)
    page_rep_1.expects(:attribute_named).with(:baz).returns('quux')

    # Get page reps proxies
    page_rep_0_proxy = Nanoc::PageRepProxy.new(page_rep_0)
    page_rep_0.expects(:to_proxy).returns(page_rep_0_proxy)
    page_rep_1_proxy = Nanoc::PageRepProxy.new(page_rep_1)
    page_rep_1.expects(:to_proxy).returns(page_rep_1_proxy)

    # Get page
    page = mock
    page.expects(:reps).times(2).returns([ page_rep_0, page_rep_1 ])

    # Get page proxy
    page_proxy = Nanoc::PageProxy.new(page)

    # Test
    assert_equal('bar',  page_proxy.reps(:default).foo)
    assert_equal('quux', page_proxy.reps(:raw).baz)
  end

end
