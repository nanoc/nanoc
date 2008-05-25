require 'helper'

class PageProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestPage

    def content
      'page content'
    end

    def path
      'page path'
    end

    def web_path
      'page web path'
    end

    def attribute_named(key)
      "attribute named #{key}"
    end

  end

  def test_get
    # Get page
    page = TestPage.new
    page_proxy = Nanoc::PageProxy.new(page)

    # Test
    assert_equal('page content',          page_proxy.content)
    assert_equal('page web path',         page_proxy.path)
    assert_equal('attribute named blah',  page_proxy.blah)
    assert_equal('attribute named blah',  page_proxy.blah?)
    assert_equal('attribute named blah!', page_proxy.blah!)
  end

end
