require 'test/helper'

class Nanoc3::Helpers::BloggingTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::Blogging
  include Nanoc3::Helpers::Text

  def test_articles
    # Create items
    @items = [ mock, mock, mock ]

    # Create item 0
    @items[0].expects(:kind).returns('item')

    # Create item 1
    @items[1].expects(:kind).returns('article')
    @items[1].expects(:created_at).returns(Time.now - 1000)

    # Create item 2
    @items[2].expects(:kind).returns('article')
    @items[2].expects(:created_at).returns(Time.now - 500)

    # Get articles
    articles = sorted_articles

    # Check
    assert_equal(2, articles.size)
    assert articles.include?(@items[1])
    assert articles.include?(@items[2])
  ensure
    # Cleanup
    @items = nil
  end

  def test_sorted_articles
    # Create items
    @items = [ mock, mock, mock ]

    # Create item 0
    @items[0].expects(:kind).returns('item')

    # Create item 1
    @items[1].expects(:kind).returns('article')
    @items[1].expects(:created_at).returns(Time.now - 1000)

    # Create item 2
    @items[2].expects(:kind).returns('article')
    @items[2].expects(:created_at).returns(Time.now - 500)

    # Get articles
    articles = sorted_articles

    # Check
    assert_equal(2,         articles.size)
    assert_equal(@items[2], articles[0])
    assert_equal(@items[1], articles[1])
  ensure
    # Cleanup
    @items = nil
  end

  def test_atom_feed
    if_have 'builder' do
      # Create items
      @items = [ mock, mock, mock ]

      # Create item 0
      @items[0].stubs(:kind).returns('item')

      # Create item 1
      @items[1].stubs(:kind).returns('article')
      @items[1].stubs(:created_at).returns(Time.now - 1000)
      @items[1].stubs(:mtime).returns(Time.now - 500)
      @items[1].stubs(:title).returns('Item One')
      @items[1].stubs(:custom_path_in_feed).returns(nil)
      @items[1].stubs(:path).returns('/item1/')
      @items[1].stubs(:content).returns('item 1 content')
      @items[1].stubs(:excerpt).returns(nil)

      # Create item 2
      @items[2].stubs(:kind).returns('article')
      @items[2].stubs(:created_at).returns(Time.now - 750)
      @items[2].stubs(:mtime).returns(Time.now - 250)
      @items[2].stubs(:title).returns('Item Two')
      @items[2].stubs(:custom_path_in_feed).returns('/item2custom/')
      @items[2].stubs(:path).returns('/item2/')
      @items[2].stubs(:content).returns('item 2 content')
      @items[2].stubs(:excerpt).returns('item 2 excerpt')

      # Create feed item
      @item = mock
      @item.stubs(:base_url).returns('http://example.com')
      @item.stubs(:title).returns('My Cool Blog')
      @item.stubs(:author_name).returns('Denis Defreyne')
      @item.stubs(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns('/journal/feed/')

      # Check
      atom_feed
    end
  end

  def test_atom_feed_without_articles
    # Mock items
    @items = [ mock, mock, mock ]
    @items[0].stubs(:kind).returns('item')
    @items[1].stubs(:kind).returns('item')
    @items[2].stubs(:kind).returns('item')

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')

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
    # Create items
    @items = [ mock, mock ]
    @items[0].stubs(:kind).returns('item')
    @items[1].stubs(:kind).returns('article')

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns(nil)
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: feed item has no base_url',
      error.message
    )
  end

  def test_atom_feed_without_title
    # Create items
    @items = [ mock, mock ]
    @items[0].stubs(:kind).returns('item')
    @items[1].stubs(:kind).returns('article')

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns(nil)
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: feed item has no title',
      error.message
    )
  end

  def test_atom_feed_without_author_name
    # Create items
    @items = [ mock, mock ]
    @items[0].stubs(:kind).returns('item')
    @items[1].stubs(:kind).returns('article')

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns(nil)
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: feed item has no author_name',
      error.message
    )
  end

  def test_atom_feed_without_author_uri
    # Create items
    @items = [ mock, mock ]
    @items[0].stubs(:kind).returns('item')
    @items[1].stubs(:kind).returns('article')

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns(nil)

    # Check
    error = assert_raises(RuntimeError) do
      atom_feed
    end
    assert_equal(
      'Cannot build Atom feed: feed item has no author_uri',
      error.message
    )
  end

  def test_atom_feed_without_articles_created_at
    # Create items
    @items = [ mock, mock, mock, mock, mock ]
    @items[0].stubs(:kind).returns('item')
    @items[1].stubs(:kind).returns('article')
    @items[1].stubs(:created_at).returns(Time.now)
    @items[2].stubs(:kind).returns('article')
    @items[2].stubs(:created_at).returns(Time.now)
    @items[3].stubs(:kind).returns('article')
    @items[3].stubs(:created_at).returns(Time.now)
    @items[4].stubs(:kind).returns('article')
    @items[4].stubs(:created_at).returns(nil)

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')

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
    # Mock items
    @items = [ mock, mock, mock, mock, mock ]
    @items[0].stubs(:kind).returns('article')
    @items[1].stubs(:kind).returns('article')
    @items[2].stubs(:kind).returns('article')
    @items[3].stubs(:kind).returns('article')
    @items[4].stubs(:kind).returns('article')

    # Mock one article
    @items[4].stubs(:created_at).returns(Time.now - 1000)
    @items[4].stubs(:mtime).returns(Time.now - 500)
    @items[4].stubs(:title).returns('Item One')
    @items[4].stubs(:custom_path_in_feed).returns(nil)
    @items[4].stubs(:path).returns('/item1/')
    @items[4].stubs(:content).returns('item 1 content')
    @items[4].stubs(:excerpt).returns(nil)

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')
    @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

    # Check
    atom_feed :articles => [ @items[4] ]
  end

  def test_atom_feed_with_limit_param
    # Mock articles
    @items = [ mock, mock, mock, mock, mock ]
    @items.each_with_index do |article, i|
      article.stubs(:kind).returns('article')
      article.stubs(:created_at).returns(Time.now - 1000*i)
      article.stubs(:mtime).returns(Time.now - 500)
      article.stubs(:title).returns("Article #{i}")
      article.stubs(:custom_path_in_feed).returns(nil)
      article.stubs(:path).returns("/articles/#{i}/")
      article.stubs(:content).returns("item #{i} content")
      article.stubs(:excerpt).returns(nil)
    end

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')
    @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

    # Check
    result = atom_feed :limit => 3, :articles => @items
    assert_match(
      Regexp.new('Article 0.*Article 1.*Article 2', Regexp::MULTILINE),
      result
    )
  end

  def test_atom_feed_with_content_proc_param
    # Mock article
    @items = [ mock ]
    @items[0].stubs(:kind).returns('article')
    @items[0].stubs(:created_at).returns(Time.now - 1000)
    @items[0].stubs(:mtime).returns(Time.now - 500)
    @items[0].stubs(:title).returns('Item One')
    @items[0].stubs(:custom_path_in_feed).returns(nil)
    @items[0].stubs(:path).returns('/item1/')
    @items[0].stubs(:excerpt).returns(nil)

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')
    @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

    # Check
    result = atom_feed :content_proc => lambda { |a| 'foobar!' }
    assert_match 'foobar!</content>', result
  end

  def test_atom_feed_with_excerpt_proc_param
    # Mock article
    @items = [ mock ]
    @items[0].stubs(:kind).returns('article')
    @items[0].stubs(:created_at).returns(Time.now - 1000)
    @items[0].stubs(:mtime).returns(Time.now - 500)
    @items[0].stubs(:title).returns('Item One')
    @items[0].stubs(:custom_path_in_feed).returns(nil)
    @items[0].stubs(:path).returns('/item1/')
    @items[0].stubs(:content).returns('some content')

    # Create feed item
    @item = mock
    @item.stubs(:base_url).returns('http://example.com')
    @item.stubs(:title).returns('My Blog Or Something')
    @item.stubs(:author_name).returns('J. Doe')
    @item.stubs(:author_uri).returns('http://example.com/~jdoe')
    @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

    # Check
    result = atom_feed :excerpt_proc => lambda { |a| 'foobar!' }
    assert_match 'foobar!</summary>', result
  end

  def test_url_for_without_custom_path_in_feed
    # Create feed item
    @item = mock
    @item.expects(:base_url).returns('http://example.com')

    # Create article
    item = mock
    item.expects(:custom_path_in_feed).returns(nil)
    item.expects(:path).returns('/foo/bar/')

    # Check
    assert_equal('http://example.com/foo/bar/', url_for(item))
  ensure
    # Cleanup
    @item = nil
  end

  def test_url_for_with_custom_path_in_feed
    # Create feed item
    @item = mock
    @item.expects(:base_url).returns('http://example.com')

    # Create article
    item = mock
    item.expects(:custom_path_in_feed).returns('/meow/woof/')

    # Check
    assert_equal('http://example.com/meow/woof/', url_for(item))
  ensure
    # Cleanup
    @item = nil
  end

  def test_feed_url_without_custom_feed_url
    # Create feed item
    @item = mock
    @item.expects(:[]).with(:feed_url).returns(nil)
    @item.expects(:base_url).returns('http://example.com')
    @item.expects(:path).returns('/foo/bar/')

    # Check
    assert_equal('http://example.com/foo/bar/', feed_url)
  ensure
    # Cleanup
    @item = nil
  end

  def test_feed_url_with_custom_feed_url
    # Create feed item
    @item = mock
    @item.expects(:[]).with(:feed_url).returns('http://example.com/feed/')

    # Check
    assert_equal('http://example.com/feed/', feed_url)
  ensure
    # Cleanup
    @item = nil
  end

  def test_atom_tag_for
    # Create feed item
    @item = mock
    @item.expects(:base_url).returns('http://example.com')

    # Create article
    item = mock
    item.expects(:created_at).returns(Time.parse('2008-05-19'))
    item.expects(:path).returns('/foo/bar/')

    # Check
    assert_equal('tag:example.com,2008-05-19:/foo/bar/', atom_tag_for(item))
  end

end
