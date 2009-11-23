# encoding: utf-8

require 'test/helper'

class Nanoc3::Helpers::BloggingTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  include Nanoc3::Helpers::Blogging
  include Nanoc3::Helpers::Text

  def test_articles
    # Create items
    @items = [ mock, mock, mock ]

    # Create item 0
    @items[0].expects(:[]).with(:kind).returns('item')

    # Create item 1
    @items[1].expects(:[]).with(:kind).returns('article')
    @items[1].expects(:[]).with(:created_at).returns((Time.now - 1000).to_s)

    # Create item 2
    @items[2].expects(:[]).with(:kind).returns('article')
    @items[2].expects(:[]).with(:created_at).returns((Time.now - 500).to_s)

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
    @items[0].expects(:[]).with(:kind).returns('item')

    # Create item 1
    @items[1].expects(:[]).with(:kind).returns('article')
    @items[1].expects(:[]).with(:created_at).returns('20-05-2008')

    # Create item 2
    @items[2].expects(:[]).with(:kind).returns('article')
    @items[2].expects(:[]).with(:created_at).returns('19-04-2009')

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
      @items[0].stubs(:[]).with(:kind).returns('item')

      # Create item 1
      @items[1].stubs(:mtime).returns(Time.now - 500)
      @items[1].stubs(:[]).with(:kind).returns('article')
      @items[1].stubs(:[]).with(:created_at).returns((Time.now - 1000).to_s)
      @items[1].stubs(:[]).with(:title).returns('Item One')
      @items[1].stubs(:[]).with(:custom_path_in_feed).returns(nil)
      @items[1].stubs(:[]).with(:excerpt).returns(nil)
      item_rep = mock
      item_rep.stubs(:path).returns("/item1/")
      item_rep.expects(:content_at_snapshot).with(:pre).returns('item rep 1 content')
      @items[1].stubs(:rep).with(:default).returns(item_rep)

      # Create item 2
      @items[2].stubs(:mtime).returns(Time.now - 250)
      @items[2].stubs(:[]).with(:kind).returns('article')
      @items[2].stubs(:[]).with(:created_at).returns((Time.now - 750).to_s)
      @items[2].stubs(:[]).with(:title).returns('Item Two')
      @items[2].stubs(:[]).with(:custom_path_in_feed).returns('/item2custom/')
      @items[2].stubs(:[]).with(:excerpt).returns('item 2 excerpt')
      item_rep = mock
      item_rep.stubs(:path).returns("/item2/")
      item_rep.expects(:content_at_snapshot).with(:pre).returns('item rep 2 content')
      @items[2].stubs(:rep).with(:default).returns(item_rep)

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      item_rep = mock
      item_rep.stubs(:path).returns("/journal/feed/")
      @item.stubs(:rep).with(:default).returns(item_rep)

      # Check
      atom_feed
    end
  end

  def test_atom_feed_without_articles
    if_have 'builder' do
      # Mock items
      @items = [ mock, mock, mock ]
      @items[0].stubs(:[]).with(:kind).returns('item')
      @items[1].stubs(:[]).with(:kind).returns('item')
      @items[2].stubs(:[]).with(:kind).returns('item')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no articles',
        error.message
      )
    end
  end

  def test_atom_feed_without_base_url
    if_have 'builder' do
      # Create items
      @items = [ mock, mock ]
      @items[0].stubs(:[]).with(:kind).returns('item')
      @items[1].stubs(:[]).with(:kind).returns('article')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({:base_url => nil})

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: site configuration has no base_url',
        error.message
      )
    end
  end

  def test_atom_feed_without_title
    if_have 'builder' do
      # Create items
      @items = [ mock, mock ]
      @items[0].stubs(:[]).with(:kind).returns('item')
      @items[1].stubs(:[]).with(:kind).returns('article')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns(nil)
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: feed item has no title',
        error.message
      )
    end
  end

  def test_atom_feed_without_author_name
    if_have 'builder' do
      # Create items
      @items = [ mock, mock ]
      @items[0].stubs(:[]).with(:kind).returns('item')
      @items[1].stubs(:[]).with(:kind).returns('article')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns(nil)
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: feed item has no author_name',
        error.message
      )
    end
  end

  def test_atom_feed_without_author_uri
    if_have 'builder' do
      # Create items
      @items = [ mock, mock ]
      @items[0].stubs(:[]).with(:kind).returns('item')
      @items[1].stubs(:[]).with(:kind).returns('article')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns(nil)

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: feed item has no author_uri',
        error.message
      )
    end
  end

  def test_atom_feed_without_articles_created_at
    if_have 'builder' do
      # Create items
      @items = [ mock, mock, mock, mock, mock ]
      @items[0].stubs(:[]).with(:kind).returns('item')
      @items[1].stubs(:[]).with(:kind).returns('article')
      @items[1].stubs(:[]).with(:created_at).returns(Time.now.to_s)
      @items[2].stubs(:[]).with(:kind).returns('article')
      @items[2].stubs(:[]).with(:created_at).returns(Time.now.to_s)
      @items[3].stubs(:[]).with(:kind).returns('article')
      @items[3].stubs(:[]).with(:created_at).returns(Time.now.to_s)
      @items[4].stubs(:[]).with(:kind).returns('article')
      @items[4].stubs(:[]).with(:created_at).returns(nil)

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(RuntimeError) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: one or more articles lack created_at',
        error.message
      )
    end
  end

  def test_atom_feed_with_articles_param
    if_have 'builder' do
      # Mock items
      @items = [ mock, mock, mock, mock, mock ]
      @items[0].stubs(:[]).with(:kind).returns('article')
      @items[1].stubs(:[]).with(:kind).returns('article')
      @items[2].stubs(:[]).with(:kind).returns('article')
      @items[3].stubs(:[]).with(:kind).returns('article')
      @items[4].stubs(:[]).with(:kind).returns('article')

      # Mock one article
      @items[4].stubs(:mtime).returns(Time.now - 500)
      @items[4].stubs(:raw_content).returns('item 1 content')
      @items[4].stubs(:[]).with(:created_at).returns((Time.now - 1000).to_s)
      @items[4].stubs(:[]).with(:title).returns('Item One')
      @items[4].stubs(:[]).with(:custom_path_in_feed).returns(nil)
      @items[4].stubs(:[]).with(:path).returns('/item1/')
      @items[4].stubs(:[]).with(:excerpt).returns(nil)
      item_rep = mock
      item_rep.stubs(:path).returns('/asdf/fdsa/')
      item_rep.stubs(:raw_path).returns('output/asdf/fdsa/index.html')
      item_rep.expects(:content_at_snapshot).with(:pre).returns('asdf')
      @items[4].stubs(:rep).with(:default).returns(item_rep)

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      atom_feed :articles => [ @items[4] ]
    end
  end

  def test_atom_feed_with_limit_param
    if_have 'builder' do
      # Mock articles
      @items = [ mock, mock, mock, mock, mock ]
      @items.each_with_index do |article, i|
        article.stubs(:mtime).returns(Time.now - 500)
        article.stubs(:[]).with(:kind).returns('article')
        article.stubs(:[]).with(:created_at).returns((Time.now - 1000*i).to_s)
        article.stubs(:[]).with(:title).returns("Article #{i}")
        article.stubs(:[]).with(:custom_path_in_feed).returns(nil)
        article.stubs(:[]).with(:path).returns("/articles/#{i}/")
        article.stubs(:[]).with(:excerpt).returns(nil)
        item_rep = mock
        item_rep.stubs(:path).returns("/articles/#{i}/")
        item_rep.stubs(:raw_path).returns("output/articles/#{i}/index.html")
        item_rep.stubs(:content_at_snapshot).with(:pre).returns("item #{i} content")
        article.stubs(:rep).with(:default).returns(item_rep)
      end

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed :limit => 3, :articles => @items
      assert_match(
        Regexp.new('Article 0.*Article 1.*Article 2', Regexp::MULTILINE),
        result
      )
    end
  end

  def test_atom_feed_sorting
    if_have 'builder' do
      # Mock articles
      @items = [ mock, mock, mock, mock ]
      @items.each_with_index do |article, i|
        article.stubs(:mtime).returns(Time.now - 500)
        article.stubs(:[]).with(:kind).returns('article')
        article.stubs(:[]).with(:title).returns("Article #{i}")
        article.stubs(:[]).with(:custom_path_in_feed).returns(nil)
        article.stubs(:[]).with(:path).returns("/articles/#{i}/")
        article.stubs(:[]).with(:excerpt).returns(nil)
        item_rep = mock
        item_rep.stubs(:path).returns("/articles/#{i}/")
        item_rep.stubs(:raw_path).returns("output/articles/#{i}/index.html")
        item_rep.stubs(:content_at_snapshot).with(:pre).returns("Article #{i} content")
        article.stubs(:rep).with(:default).returns(item_rep)
      end
      @items[0].stubs(:[]).with(:created_at).returns('23-02-2009')
      @items[1].stubs(:[]).with(:created_at).returns('22-03-2009')
      @items[2].stubs(:[]).with(:created_at).returns('21-04-2009')
      @items[3].stubs(:[]).with(:created_at).returns('20-05-2009')

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed
      assert_match(
        Regexp.new('Article 3.*Article 2.*Article 1.*Article 0', Regexp::MULTILINE),
        result
      )
    end
  end

  def test_atom_feed_with_content_proc_param
    if_have 'builder' do
      # Mock article
      @items = [ mock ]
      @items[0].stubs(:mtime).returns(Time.now - 500)
      @items[0].stubs(:[]).with(:kind).returns('article')
      @items[0].stubs(:[]).with(:created_at).returns((Time.now - 1000).to_s)
      @items[0].stubs(:[]).with(:title).returns('Item One')
      @items[0].stubs(:[]).with(:custom_path_in_feed).returns(nil)
      @items[0].stubs(:[]).with(:excerpt).returns(nil)
      item_rep = mock
      item_rep.stubs(:path).returns('/item1/')
      item_rep.stubs(:raw_path).returns('output/item1/index.html')
      @items[0].stubs(:rep).with(:default).returns(item_rep)

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed :content_proc => lambda { |a| 'foobar!' }
      assert_match 'foobar!</content>', result
    end
  end

  def test_atom_feed_with_excerpt_proc_param
    if_have 'builder' do
      # Mock article
      @items = [ mock ]
      @items[0].stubs(:mtime).returns(Time.now - 500)
      @items[0].stubs(:[]).with(:kind).returns('article')
      @items[0].stubs(:[]).with(:created_at).returns((Time.now - 1000).to_s)
      @items[0].stubs(:[]).with(:title).returns('Item One')
      @items[0].stubs(:[]).with(:custom_path_in_feed).returns(nil)
      @items[0].stubs(:raw_content).returns('some content')
      item_rep = mock
      item_rep.stubs(:path).returns('/item1/')
      item_rep.stubs(:raw_path).returns('output/item1/index.html')
      item_rep.expects(:content_at_snapshot).with(:pre).returns('foo')
      @items[0].stubs(:rep).with(:default).returns(item_rep)

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed :excerpt_proc => lambda { |a| 'foobar!' }
      assert_match 'foobar!</summary>', result
    end
  end

  def test_atom_feed_with_item_without_path
    if_have 'builder' do
      # Create items
      @items = [ mock ]
      @items[0].stubs(:mtime).returns(Time.now - 500)
      @items[0].stubs(:identifier).returns('/item/')
      @items[0].stubs(:[]).with(:kind).returns('article')
      @items[0].stubs(:[]).with(:created_at).returns((Time.now - 1000).to_s)
      @items[0].stubs(:[]).with(:title).returns('Item One')
      @items[0].stubs(:[]).with(:custom_path_in_feed).returns(nil)
      @items[0].stubs(:[]).with(:excerpt).returns(nil)
      item_rep = mock
      item_rep.stubs(:path).returns(nil)
      @items[0].stubs(:rep).with(:default).returns(item_rep)

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:identifier).returns('/feed/')
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      item_rep = mock
      item_rep.stubs(:path).returns("/journal/feed/")
      @item.stubs(:rep).with(:default).returns(item_rep)

      # Check
      atom_feed
    end
  end

  def test_url_for_without_custom_path_in_feed
    # Mock site
    @site = mock
    @site.stubs(:config).returns({ :base_url => 'http://example.com' })

    # Create article
    item = mock
    item.expects(:[]).with(:custom_path_in_feed).returns(nil)
    item_rep = mock
    item_rep.expects(:path).returns('/foo/bar/')
    item.expects(:rep).with(:default).returns(item_rep)

    # Check
    assert_equal('http://example.com/foo/bar/', url_for(item))
  ensure
    # Cleanup
    @item = nil
  end

  def test_url_for_with_custom_path_in_feed
    # Mock site
    @site = mock
    @site.stubs(:config).returns({ :base_url => 'http://example.com' })

    # Create article
    item = mock
    item.expects(:[]).with(:custom_path_in_feed).returns('/meow/woof/')

    # Check
    assert_equal('http://example.com/meow/woof/', url_for(item))
  ensure
    # Cleanup
    @item = nil
  end

  def test_url_for_without_base_url
    # Mock site
    @site = mock
    @site.stubs(:config).returns({})

    # Check
    assert_raises(RuntimeError) do
      url_for(nil)
    end
  end

  def test_url_for_without_path
    # Mock site
    @site = mock
    @site.stubs(:config).returns({ :base_url => 'http://example.com' })

    # Create article
    item = mock
    item.expects(:[]).with(:custom_path_in_feed).returns(nil)
    item_rep = mock
    item_rep.expects(:path).returns(nil)
    item.expects(:rep).with(:default).returns(item_rep)

    # Check
    assert_equal(nil, url_for(item))
  end

  def test_feed_url_without_custom_feed_url
    # Mock site
    @site = mock
    @site.stubs(:config).returns({ :base_url => 'http://example.com' })

    # Create feed item
    @item = mock
    @item.expects(:[]).with(:feed_url).returns(nil)
    item_rep = mock
    item_rep.expects(:path).returns('/foo/bar/')
    @item.expects(:rep).with(:default).returns(item_rep)

    # Check
    assert_equal('http://example.com/foo/bar/', feed_url)
  ensure
    # Cleanup
    @item = nil
  end

  def test_feed_url_with_custom_feed_url
    # Mock site
    @site = mock
    @site.stubs(:config).returns({ :base_url => 'http://example.com' })

    # Create feed item
    @item = mock
    @item.expects(:[]).with(:feed_url).returns('http://example.com/feed/')

    # Check
    assert_equal('http://example.com/feed/', feed_url)
  ensure
    # Cleanup
    @item = nil
  end

  def test_feed_url_without_base_url
    # Mock site
    @site = mock
    @site.stubs(:config).returns({})

    # Check
    assert_raises(RuntimeError) do
      feed_url
    end
  end

  def test_atom_tag_for_with_path
    # Mock site
    @site = mock
    @site.stubs(:config).returns({ :base_url => 'http://example.com' })

    # Create article reps
    item_rep = mock
    item_rep.expects(:path).returns('/foo/bar/')

    # Create article
    item = mock
    item.expects(:[]).with(:created_at).returns('2008-05-19')
    item.expects(:rep).with(:default).returns(item_rep)

    # Check
    assert_equal('tag:example.com,2008-05-19:/foo/bar/', atom_tag_for(item))
  end

  def test_atom_tag_for_without_path
    # Mock site
    @site = mock
    @site.stubs(:config).returns({ :base_url => 'http://example.com' })

    # Create article reps
    item_rep = mock
    item_rep.expects(:path).returns(nil)

    # Create article
    item = mock
    item.expects(:[]).with(:created_at).returns('2008-05-19')
    item.expects(:rep).with(:default).returns(item_rep)
    item.expects(:identifier).returns('/baz/qux/')

    # Check
    assert_equal('tag:example.com,2008-05-19:/baz/qux/', atom_tag_for(item))
  end

end
