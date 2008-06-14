require 'helper'

class Nanoc::PageRepProxyTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  class TestPageRep

    attr_reader :page

    def initialize(page)
      @page = page
    end

    def to_proxy
      @proxy ||= Nanoc::PageRepProxy.new(self)
    end

    def name
      :default
    end

    def web_path
      "page rep web path"
    end

    def content
      "page rep content"
    end

    def attribute_named(key)
      "page rep attribute named #{key}"
    end

  end

  class TestPage

    def to_proxy
      @proxy ||= Nanoc::PageProxy.new(self)
    end

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
      "page attribute named #{key}"
    end

    def reps
      @reps ||= [ TestPageRep.new(self) ]
    end

  end

  def test_get
    # Get page
    page = TestPage.new
    page_rep = page.reps[0]
    page_rep_proxy = page_rep.to_proxy

    # Test
    assert_equal('page rep content',                page_rep_proxy.content)
    assert_equal('page attribute named moo',        page_rep_proxy.page.moo)
    assert_equal('page rep web path',               page_rep_proxy.path)
    assert_equal('page rep attribute named blah',   page_rep_proxy.blah)
    assert_equal('page rep attribute named blah',   page_rep_proxy.blah?)
    assert_equal('page rep attribute named blah!',  page_rep_proxy.blah!)
  end

end
