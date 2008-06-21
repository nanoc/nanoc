require 'helper'

class Nanoc::Extensions::BloggingTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Extensions::Blogging

  def test_sorted_articles
    # Create pages
    @pages = [ mock, mock, mock ]
    @pages[0].expects(:kind).returns('page')
    @pages[1].expects(:kind).returns('article')
    @pages[1].expects(:created_at).returns(Time.now - 1000)
    @pages[2].expects(:kind).returns('article')
    @pages[2].expects(:created_at).returns(Time.now - 500)

    # Get articles
    articles = sorted_articles

    # Check
    assert_equal(2,         articles.size)
    assert_equal(@pages[2], articles[0])
    assert_equal(@pages[1], articles[1])
  ensure
    # Cleanup
    @pages = nil
  end

  def test_atom_feed
    # TODO implement
  end

  def test_url_for_without_custom_path_in_feed
    # Create feed page
    @page = mock
    @page.expects(:base_url).returns('http://example.com')

    # Create article
    page = mock
    page.expects(:custom_path_in_feed).returns(nil)
    page.expects(:path).returns('/foo/bar/')

    # Check
    assert_equal('http://example.com/foo/bar/', url_for(page))
  ensure
    # Cleanup
    @page = nil
  end

  def test_url_for_with_custom_path_in_feed
    # Create feed page
    @page = mock
    @page.expects(:base_url).returns('http://example.com')

    # Create article
    page = mock
    page.expects(:custom_path_in_feed).returns('/meow/woof/')

    # Check
    assert_equal('http://example.com/meow/woof/', url_for(page))
  ensure
    # Cleanup
    @page = nil
  end

  def test_feed_url_without_custom_feed_url
    # Create feed page
    @page = mock
    @page.expects(:feed_url).returns(nil)
    @page.expects(:base_url).returns('http://example.com')
    @page.expects(:path).returns('/foo/bar/')

    # Check
    assert_equal('http://example.com/foo/bar/', feed_url)
  ensure
    # Cleanup
    @page = nil
  end

  def test_feed_url_with_custom_feed_url
    # Create feed page
    @page = mock
    @page.expects(:feed_url).returns('http://example.com/feed/')

    # Check
    assert_equal('http://example.com/feed/', feed_url)
  ensure
    # Cleanup
    @page = nil
  end

  def test_atom_tag_for
    # Create feed page
    @page = mock
    @page.expects(:base_url).returns('http://example.com')

    # Create article
    page = mock
    page.expects(:created_at).returns(Time.parse('2008-05-19'))
    page.expects(:path).returns('/foo/bar/')

    # Check
    assert_equal('tag:example.com,2008-05-19:/foo/bar/', atom_tag_for(page))
  end

end
