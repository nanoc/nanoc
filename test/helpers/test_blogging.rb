require 'helper'

class Nanoc::Helpers::BloggingTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::Blogging
  include Nanoc::Helpers::Text

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

  def test_sorted_articles_with_feed_tag
    # Create pages
    @pages = [ mock, mock, mock, mock, mock ]

    # Create page 0
    @pages[0].expects(:kind).times(2).returns('page')
    @pages[0].stubs(:feed_tag).returns('foobar')
    @pages[0].stubs(:feed_tags).returns(nil)

    # Create page 1
    @pages[1].expects(:kind).times(2).returns('article')
    @pages[1].expects(:created_at).times(2).returns(Time.now - 500)
    @pages[1].stubs(:feed_tag).returns('foobar')
    @pages[1].stubs(:feed_tags).returns(nil)

    # Create page 2
    @pages[2].expects(:kind).times(2).returns('article')
    @pages[2].stubs(:feed_tag).returns('barbaz')
    @pages[2].stubs(:feed_tags).returns(nil)

    # Create page 3
    @pages[3].expects(:kind).times(2).returns('article')
    @pages[3].expects(:created_at).times(2).returns(Time.now - 250)
    @pages[3].stubs(:feed_tag).returns(nil)
    @pages[3].stubs(:feed_tags).returns([ 'foobar' ])

    # Create page 4
    @pages[4].expects(:kind).times(2).returns('article')
    @pages[4].stubs(:feed_tag).returns(nil)
    @pages[4].stubs(:feed_tags).returns([ 'blabla' ])

    # Get articles
    articles = sorted_articles('foobar')

    # Check
    assert_equal(2,         articles.size)
    assert_equal(@pages[3], articles[0])
    assert_equal(@pages[1], articles[1])

    # Get articles
    articles = sorted_articles([ 'foobar' ])

    # Check
    assert_equal(2,         articles.size)
    assert_equal(@pages[3], articles[0])
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
      @pages[0].expects(:kind).at_least_once.returns('page')

      # Create page 1
      @pages[1].expects(:kind).at_least_once.returns('article')
      @pages[1].expects(:created_at).at_least_once.returns(Time.now - 1000)
      @pages[1].expects(:mtime).at_least_once.returns(Time.now - 500)
      @pages[1].expects(:title).returns('Page One')
      @pages[1].expects(:custom_path_in_feed).returns(nil)
      @pages[1].expects(:path).at_least_once.returns('/page1/')
      @pages[1].expects(:content).returns('page 1 content')
      @pages[1].expects(:excerpt).returns(nil)

      # Create page 2
      @pages[2].expects(:kind).at_least_once.returns('article')
      @pages[2].expects(:created_at).at_least_once.returns(Time.now - 750)
      @pages[2].expects(:mtime).at_least_once.returns(Time.now - 250)
      @pages[2].expects(:title).returns('Page Two')
      @pages[2].expects(:custom_path_in_feed).returns('/page2custom/')
      @pages[2].expects(:path).at_least_once.returns('/page2/')
      @pages[2].expects(:content).returns('page 2 content')
      @pages[2].expects(:excerpt).returns('page 2 excerpt')

      # Create feed page
      @page = mock
      @page.expects(:base_url).at_least_once.returns('http://example.com')
      @page.expects(:title).returns('My Cool Blog')
      @page.expects(:author_name).returns('Denis Defreyne')
      @page.expects(:author_uri).returns('http://stoneship.org/')
      @page.expects(:[]).with(:feed_url).returns(nil)
      @page.expects(:path).returns('/journal/feed/')

      # Check
      assert_nothing_raised do
        atom_feed
      end
    end
  end

  def test_atom_feed_with_feed_tag
    if_have 'builder' do
      # Create pages
      @pages = [ mock, mock, mock ]

      # Create page 0
      @pages[0].expects(:kind).at_least_once.returns('page')

      # Create page 1
      @pages[1].expects(:kind).at_least_once.returns('article')
      @pages[1].expects(:feed_tag).returns(nil)
      @pages[1].expects(:feed_tags).returns(nil)

      # Create page 2
      @pages[2].expects(:kind).at_least_once.returns('article')
      @pages[2].expects(:created_at).at_least_once.returns(Time.now - 750)
      @pages[2].expects(:mtime).at_least_once.returns(Time.now - 250)
      @pages[2].expects(:title).returns('Page Two')
      @pages[2].expects(:custom_path_in_feed).returns('/page2custom/')
      @pages[2].expects(:path).at_least_once.returns('/page2/')
      @pages[2].expects(:content).returns('page 2 content')
      @pages[2].expects(:excerpt).returns('page 2 excerpt')
      @pages[2].expects(:feed_tag).returns('foobar')

      # Create feed page
      @page = mock
      @page.expects(:base_url).at_least_once.returns('http://example.com')
      @page.expects(:title).returns('My Cool Blog')
      @page.expects(:author_name).returns('Denis Defreyne')
      @page.expects(:author_uri).returns('http://stoneship.org/')
      @page.expects(:[]).with(:feed_url).returns(nil)
      @page.expects(:path).returns('/journal/feed/')

      # Check
      assert_nothing_raised do
        atom_feed(:feed_tag => 'foobar')
      end
    end
  end

  def test_atom_feed_with_custom_procs
    if_have 'builder' do
      # Create page
      @pages = [ mock ]
      @pages[0].expects(:kind).at_least_once.returns('article')
      @pages[0].expects(:created_at).at_least_once.returns(Time.now - 750)
      @pages[0].expects(:mtime).at_least_once.returns(Time.now - 250)
      @pages[0].expects(:title).returns('Page Two')
      @pages[0].expects(:custom_path_in_feed).returns('/page2custom/')
      @pages[0].expects(:path).at_least_once.returns('/page2/')
      @pages[0].expects(:feed_tag).returns('foobar')
      @pages[0].expects(:content).returns('blah blah this is a very long and boring text')

      # Create feed page
      @page = mock
      @page.expects(:base_url).at_least_once.returns('http://example.com')
      @page.expects(:title).returns('My Cool Blog')
      @page.expects(:author_name).returns('Denis Defreyne')
      @page.expects(:author_uri).returns('http://stoneship.org/')
      @page.expects(:[]).with(:feed_url).returns(nil)
      @page.expects(:path).returns('/journal/feed/')

      # Create procs
      content_proc = lambda { |article| excerptize(article.content, :length => 18) }
      excerpt_proc = lambda { |article| 'this is the excerpt yarly' }

      # Check
      assert_nothing_raised do
        result = atom_feed(:feed_tag => 'foobar', :content_proc => content_proc, :excerpt_proc => excerpt_proc)
        assert_match(/blah blah this .../, result)
        assert_match(/this is the excerpt yarly/, result)
      end
    end
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
