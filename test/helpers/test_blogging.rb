require 'helper'

class Nanoc::Helpers::BloggingTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::Blogging
  include Nanoc::Helpers::Text

  def test_articles
    # Create pages
    @pages = [ mock, mock, mock ]

    # Create page 0
    @pages[0].expects(:kind).returns('page')

    # Create page 1
    @pages[1].expects(:kind).returns('article')
    @pages[1].expects(:created_at).returns(Time.now - 1000)

    # Create page 2
    @pages[2].expects(:kind).returns('article')
    @pages[2].expects(:created_at).returns(Time.now - 500)

    # Get articles
    articles = sorted_articles

    # Check
    assert_equal(2, articles.size)
    assert articles.include?(@pages[1])
    assert articles.include?(@pages[2])
  ensure
    # Cleanup
    @pages = nil
  end

  def test_sorted_articles
    # Create pages
    @pages = [ mock, mock, mock ]

    # Create page 0
    @pages[0].expects(:kind).returns('page')

    # Create page 1
    @pages[1].expects(:kind).returns('article')
    @pages[1].expects(:created_at).returns(Time.now - 1000)

    # Create page 2
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
    if_have 'builder' do
      # Create pages
      @pages = [ mock, mock, mock ]

      # Create page 0
      @pages[0].stubs(:kind).returns('page')

      # Create page 1
      @pages[1].stubs(:kind).returns('article')
      @pages[1].stubs(:created_at).returns(Time.now - 1000)
      @pages[1].stubs(:mtime).returns(Time.now - 500)
      @pages[1].stubs(:title).returns('Page One')
      @pages[1].stubs(:custom_path_in_feed).returns(nil)
      @pages[1].stubs(:path).returns('/page1/')
      @pages[1].stubs(:content).returns('page 1 content')
      @pages[1].stubs(:excerpt).returns(nil)

      # Create page 2
      @pages[2].stubs(:kind).returns('article')
      @pages[2].stubs(:created_at).returns(Time.now - 750)
      @pages[2].stubs(:mtime).returns(Time.now - 250)
      @pages[2].stubs(:title).returns('Page Two')
      @pages[2].stubs(:custom_path_in_feed).returns('/page2custom/')
      @pages[2].stubs(:path).returns('/page2/')
      @pages[2].stubs(:content).returns('page 2 content')
      @pages[2].stubs(:excerpt).returns('page 2 excerpt')

      # Create feed page
      @page = mock
      @page.stubs(:base_url).returns('http://example.com')
      @page.stubs(:title).returns('My Cool Blog')
      @page.stubs(:author_name).returns('Denis Defreyne')
      @page.stubs(:author_uri).returns('http://stoneship.org/')
      @page.stubs(:[]).with(:feed_url).returns(nil)
      @page.stubs(:path).returns('/journal/feed/')

      # Check
      atom_feed
    end
  end

  def test_atom_feed_without_articles
    # Mock pages
    @pages = [ mock, mock, mock ]
    @pages[0].stubs(:kind).returns('page')
    @pages[1].stubs(:kind).returns('page')
    @pages[2].stubs(:kind).returns('page')

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns('http://example.com')
    @page.stubs(:title).returns('My Blog Or Something')
    @page.stubs(:author_name).returns('J. Doe')
    @page.stubs(:author_uri).returns('http://example.com/~jdoe')

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: no articles',
      error.message
    )
  end

  def test_atom_feed_without_base_url
    # Create pages
    @pages = [ mock, mock ]
    @pages[0].stubs(:kind).returns('page')
    @pages[1].stubs(:kind).returns('article')

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns(nil)
    @page.stubs(:title).returns('My Blog Or Something')
    @page.stubs(:author_name).returns('J. Doe')
    @page.stubs(:author_uri).returns('http://example.com/~jdoe')

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: feed page has no base_url',
      error.message
    )
  end

  def test_atom_feed_without_title
    # Create pages
    @pages = [ mock, mock ]
    @pages[0].stubs(:kind).returns('page')
    @pages[1].stubs(:kind).returns('article')

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns('http://example.com')
    @page.stubs(:title).returns(nil)
    @page.stubs(:author_name).returns('J. Doe')
    @page.stubs(:author_uri).returns('http://example.com/~jdoe')

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: feed page has no title',
      error.message
    )
  end

  def test_atom_feed_without_author_name
    # Create pages
    @pages = [ mock, mock ]
    @pages[0].stubs(:kind).returns('page')
    @pages[1].stubs(:kind).returns('article')

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns('http://example.com')
    @page.stubs(:title).returns('My Blog Or Something')
    @page.stubs(:author_name).returns(nil)
    @page.stubs(:author_uri).returns('http://example.com/~jdoe')

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: feed page has no author_name',
      error.message
    )
  end

  def test_atom_feed_without_author_uri
    # Create pages
    @pages = [ mock, mock ]
    @pages[0].stubs(:kind).returns('page')
    @pages[1].stubs(:kind).returns('article')

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns('http://example.com')
    @page.stubs(:title).returns('My Blog Or Something')
    @page.stubs(:author_name).returns('J. Doe')
    @page.stubs(:author_uri).returns(nil)

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: feed page has no author_uri',
      error.message
    )
  end

  def test_atom_feed_without_articles_created_at
    # Create pages
    @pages = [ mock, mock, mock, mock, mock ]
    @pages[0].stubs(:kind).returns('page')
    @pages[1].stubs(:kind).returns('article')
    @pages[1].stubs(:created_at).returns(Time.now)
    @pages[2].stubs(:kind).returns('article')
    @pages[2].stubs(:created_at).returns(Time.now)
    @pages[3].stubs(:kind).returns('article')
    @pages[3].stubs(:created_at).returns(Time.now)
    @pages[4].stubs(:kind).returns('article')
    @pages[4].stubs(:created_at).returns(nil)

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns('http://example.com')
    @page.stubs(:title).returns('My Blog Or Something')
    @page.stubs(:author_name).returns('J. Doe')
    @page.stubs(:author_uri).returns('http://example.com/~jdoe')

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: one or more articles lack created_at',
      error.message
    )
  end

  def test_atom_feed_with_articles_param
    # Mock pages
    @pages = [ mock, mock, mock, mock, mock ]
    @pages[0].stubs(:kind).returns('article')
    @pages[1].stubs(:kind).returns('article')
    @pages[2].stubs(:kind).returns('article')
    @pages[3].stubs(:kind).returns('article')
    @pages[4].stubs(:kind).returns('article')

    # Mock one article
    @pages[4].stubs(:created_at).returns(Time.now - 1000)
    @pages[4].stubs(:mtime).returns(Time.now - 500)
    @pages[4].stubs(:title).returns('Page One')
    @pages[4].stubs(:custom_path_in_feed).returns(nil)
    @pages[4].stubs(:path).returns('/page1/')
    @pages[4].stubs(:content).returns('page 1 content')
    @pages[4].stubs(:excerpt).returns(nil)

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns('http://example.com')
    @page.stubs(:title).returns('My Blog Or Something')
    @page.stubs(:author_name).returns('J. Doe')
    @page.stubs(:author_uri).returns('http://example.com/~jdoe')
    @page.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

    # Check
    atom_feed :articles => [ @pages[4] ]
  end

  def test_atom_feed_with_content_proc_param
    # Mock article
    @pages = [ mock ]
    @pages[0].stubs(:kind).returns('article')
    @pages[0].stubs(:created_at).returns(Time.now - 1000)
    @pages[0].stubs(:mtime).returns(Time.now - 500)
    @pages[0].stubs(:title).returns('Page One')
    @pages[0].stubs(:custom_path_in_feed).returns(nil)
    @pages[0].stubs(:path).returns('/page1/')
    @pages[0].stubs(:excerpt).returns(nil)

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns('http://example.com')
    @page.stubs(:title).returns('My Blog Or Something')
    @page.stubs(:author_name).returns('J. Doe')
    @page.stubs(:author_uri).returns('http://example.com/~jdoe')
    @page.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

    # Check
    result = atom_feed :content_proc => lambda { |a| 'foobar!' }
    assert_match 'foobar!</content>', result
  end

  def test_atom_feed_with_excerpt_proc_param
    # Mock article
    @pages = [ mock ]
    @pages[0].stubs(:kind).returns('article')
    @pages[0].stubs(:created_at).returns(Time.now - 1000)
    @pages[0].stubs(:mtime).returns(Time.now - 500)
    @pages[0].stubs(:title).returns('Page One')
    @pages[0].stubs(:custom_path_in_feed).returns(nil)
    @pages[0].stubs(:path).returns('/page1/')
    @pages[0].stubs(:content).returns('some content')

    # Create feed page
    @page = mock
    @page.stubs(:base_url).returns('http://example.com')
    @page.stubs(:title).returns('My Blog Or Something')
    @page.stubs(:author_name).returns('J. Doe')
    @page.stubs(:author_uri).returns('http://example.com/~jdoe')
    @page.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

    # Check
    result = atom_feed :excerpt_proc => lambda { |a| 'foobar!' }
    assert_match 'foobar!</summary>', result
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
    @page.expects(:[]).with(:feed_url).returns(nil)
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
    @page.expects(:[]).with(:feed_url).returns('http://example.com/feed/')

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
