require 'helper'

class Nanoc::PageProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestPageRep

    def web_path
      "page rep web path"
    end

    def content
      "page rep content"
    end

  end

  class TestPage

    def content
      'page content'
    end

    def path
      'page path'
    end

    def mtime
      Time.parse('2008-05-19')
    end

    def web_path
      'page web path'
    end

    def attribute_named(key)
      "attribute named #{key}"
    end

    def reps
      { :default => TestPageRep.new }
    end

  end

  def test_get
    # Get page
    page = TestPage.new
    page_proxy = Nanoc::PageProxy.new(page)

    # Test
    assert_equal('page rep content',        page_proxy.content)
    assert_equal('page rep web path',       page_proxy.path)
    assert_equal(Time.parse('2008-05-19'),  page_proxy.mtime)
    assert_equal('attribute named blah',    page_proxy.blah)
    assert_equal('attribute named blah',    page_proxy.blah?)
    assert_equal('attribute named blah!',   page_proxy.blah!)
  end

end
