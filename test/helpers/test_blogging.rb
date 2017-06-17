# frozen_string_literal: true

require 'helper'

class Nanoc::Helpers::BloggingTest < Nanoc::TestCase
  include Nanoc::Helpers::Blogging
  include Nanoc::Helpers::Text

  def mock_article
    item = mock
    item.stubs(:[]).with(:updated_at).returns(Time.now - 500)
    item.stubs(:[]).with(:kind).returns('article')
    item.stubs(:[]).with(:created_at).returns(Time.now - 1000)
    item.stubs(:[]).with(:title).returns('An Item')
    item.stubs(:[]).with(:custom_path_in_feed).returns(nil)
    item.stubs(:[]).with(:custom_url_in_feed).returns(nil)
    item.stubs(:[]).with(:excerpt).returns(nil)
    item.stubs(:path).returns('/item/')
    item.stubs(:[]).with(:author_name).returns(nil)
    item.stubs(:[]).with(:author_uri).returns(nil)
    item.stubs(:compiled_content).returns('item content')
    item
  end

  def mock_item
    item = mock
    item.stubs(:[]).with(:kind).returns('item')
    item
  end

  def setup
    super

    config = Nanoc::Int::Configuration.new.with_defaults
    items = Nanoc::Int::IdentifiableCollection.new(config)
    layouts = Nanoc::Int::IdentifiableCollection.new(config)
    dep_store = Nanoc::Int::DependencyStore.new(items, layouts, config)
    dependency_tracker = Nanoc::Int::DependencyTracker.new(dep_store)

    @view_context = Nanoc::ViewContext.new(
      reps: :__irrelevant__,
      items: nil,
      dependency_tracker: dependency_tracker,
      compilation_context: :__irrelevant__,
      snapshot_repo: :__irrelevant_snapshot_repo,
    )
  end

  def test_atom_feed
    if_have 'builder' do
      # Create items
      @items = [mock, mock_article, mock_article]

      # Create item 0
      @items[0].stubs(:[]).with(:kind).returns('item')

      # Create item 1
      @items[1].stubs(:[]).with(:updated_at).returns(Date.today - 1)
      @items[1].stubs(:[]).with(:kind).returns('article')
      @items[1].stubs(:[]).with(:created_at).returns((Date.today - 2).to_s)
      @items[1].stubs(:[]).with(:title).returns('Item One')
      @items[1].stubs(:[]).with(:custom_path_in_feed).returns(nil)
      @items[1].stubs(:[]).with(:custom_url_in_feed).returns(nil)
      @items[1].stubs(:[]).with(:excerpt).returns(nil)
      @items[1].stubs(:path).returns('/item1/')
      @items[1].expects(:compiled_content).with(snapshot: :pre).returns('item 1 content')

      # Create item 2
      @items[2].expects(:compiled_content).with(snapshot: :pre).returns('item 2 content')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns('/journal/feed/')

      # Check
      atom_feed
    end
  end

  def test_atom_feed_with_times
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article, mock_article]

      # Create item 1
      @items[1].stubs(:[]).with(:updated_at).returns(Time.now - 500)
      @items[1].stubs(:[]).with(:created_at).returns(Time.now - 1000)
      @items[1].expects(:compiled_content).returns('item 1 content')

      # Create item 2
      @items[2].stubs(:[]).with(:updated_at).returns(Time.now - 250)
      @items[2].stubs(:[]).with(:created_at).returns(Time.now - 1200)
      @items[2].expects(:compiled_content).returns('item 2 content')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns('/journal/feed/')

      # Check
      atom_feed
    end
  end

  def test_atom_feed_updated_is_most_recent
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article, mock_article]

      # Create item 1
      @items[1].stubs(:[]).with(:updated_at).returns(nil)
      @items[1].stubs(:[]).with(:created_at).returns(Time.parse('2016-12-01 17:20:00 +00:00'))
      @items[1].expects(:compiled_content).returns('item 1 content')

      # Create item 2
      @items[2].stubs(:[]).with(:updated_at).returns(nil)
      @items[2].stubs(:[]).with(:created_at).returns(Time.parse('2016-12-01 18:40:00 +00:00'))
      @items[2].expects(:compiled_content).returns('item 2 content')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns('/journal/feed/')

      # Check
      assert_match(%r{<title>My Cool Blog</title>\n  <updated>2016-12-01T18:40:00Z</updated>}, atom_feed)
    end
  end

  def test_atom_feed_updated_is_most_recent_updated_at
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article, mock_article]

      # Create item 1
      @items[1].stubs(:[]).with(:updated_at).returns(Time.parse('2016-12-01 19:20:00 +00:00'))
      @items[1].stubs(:[]).with(:created_at).returns(Time.parse('2016-12-01 17:20:00 +00:00'))
      @items[1].expects(:compiled_content).returns('item 1 content')

      # Create item 2
      @items[2].stubs(:[]).with(:updated_at).returns(Time.parse('2016-12-01 20:40:00 +00:00'))
      @items[2].stubs(:[]).with(:created_at).returns(Time.parse('2016-12-01 18:40:00 +00:00'))
      @items[2].expects(:compiled_content).returns('item 2 content')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns('/journal/feed/')

      # Check
      assert_match(%r{<title>My Cool Blog</title>\n  <updated>2016-12-01T20:40:00Z</updated>}, atom_feed)
    end
  end

  def test_atom_feed_without_articles
    if_have 'builder' do
      # Mock items
      @items = [mock_item, mock_item]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(Nanoc::Int::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no articles',
        error.message,
      )
    end
  end

  def test_atom_feed_without_base_url
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: nil })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(Nanoc::Int::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: site configuration has no base_url',
        error.message,
      )
    end
  end

  def test_atom_feed_without_title
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns(nil)
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(Nanoc::Int::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no title in params, item or site config',
        error.message,
      )
    end
  end

  def test_atom_feed_without_author_name
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns(nil)
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(Nanoc::Int::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no author_name in params, item or site config',
        error.message,
      )
    end
  end

  def test_atom_feed_with_author_name_and_uri_from_content_item
    if_have 'builder' do
      # Create items
      @items = [mock_article]

      # Create item 1
      @items[0].stubs(:[]).with(:author_name).returns('Don Alias')
      @items[0].stubs(:[]).with(:author_uri).returns('http://don.example.com/')
      @items[0].expects(:compiled_content).returns('item 1 content')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com/' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:kind).returns(nil)
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns('/journal/feed/')

      # Check
      # TODO: Use xpath matchers for more specific test
      result = atom_feed
      # Still should keep feed level author
      assert_match(
        /#{Regexp.escape('<name>Denis Defreyne</name>')}/, #'
        result,
      )
      assert_match(
        /#{Regexp.escape('<uri>http://stoneship.org/</uri>')}/, #'
        result,
      )

      # Overrides on specific items
      assert_match(
        /#{Regexp.escape('<name>Don Alias</name>')}/, #'
        result,
      )
      assert_match(
        /#{Regexp.escape('<uri>http://don.example.com/</uri>')}/, #'
        result,
      )
    end
  end

  def test_atom_feed_without_author_uri
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns(nil)

      # Check
      error = assert_raises(Nanoc::Int::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no author_uri in params, item or site config',
        error.message,
      )
    end
  end

  def test_atom_feed_without_articles_created_at
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article, mock_article]
      @items[1].stubs(:[]).with(:created_at).returns(Time.now.to_s)
      @items[2].stubs(:[]).with(:created_at).returns(nil)

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')

      # Check
      error = assert_raises(Nanoc::Int::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: one or more articles lack created_at',
        error.message,
      )
    end
  end

  def test_atom_feed_with_title_author_name_and_uri_as_params
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article]
      @items[1].expects(:compiled_content).with(snapshot: :pre).returns('asdf')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns(nil)
      @item.stubs(:[]).with(:author_name).returns(nil)
      @item.stubs(:[]).with(:author_uri).returns(nil)
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      atom_feed(
        author_name: 'Bob',
        author_uri: 'http://example.com/~bob/',
        title: 'My Blog Or Something',
      )
    end
  end

  def test_atom_feed_with_title_author_name_and_uri_from_config
    if_have 'builder' do
      # Create items
      @items = [mock_item, mock_article]
      @items[1].expects(:compiled_content).with(snapshot: :pre).returns('asdf')

      # Mock site
      config_hash =
        {
          author_name: 'Bob',
          author_uri: 'http://example.com/~bob/',
          title: 'My Blog Or Something',
          base_url: 'http://example.com',
        }
      config = Nanoc::Int::Configuration.new(hash: config_hash)
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns(nil)
      @item.stubs(:[]).with(:author_name).returns(nil)
      @item.stubs(:[]).with(:author_uri).returns(nil)
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      atom_feed
    end
  end

  def test_atom_feed_with_articles_param
    if_have 'builder' do
      # Mock items
      @items = [mock_article, mock_article]

      @items[0].expects(:compiled_content).never
      @items[1].stubs(:[]).with(:title).returns('Item One')
      @items[1].expects(:compiled_content).with(snapshot: :pre).returns('asdf')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      atom_feed articles: [@items[1]]
    end
  end

  def test_atom_feed_with_limit_param
    if_have 'builder' do
      # Mock articles
      @items = [mock_article, mock_article]
      @items.each_with_index do |article, i|
        article.stubs(:[]).with(:title).returns("Article #{i}")
        article.stubs(:[]).with(:created_at).returns(Time.now - i)
      end

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed limit: 1, articles: @items
      assert_match(
        Regexp.new('Article 0', Regexp::MULTILINE),
        result,
      )
      refute_match(
        Regexp.new('Article 1', Regexp::MULTILINE),
        result,
      )
    end
  end

  def test_atom_feed_sorting
    if_have 'builder' do
      # Mock articles
      @items = [mock_article, mock_article]
      @items.each_with_index do |article, i|
        article.stubs(:[]).with(:title).returns("Article #{i}")
      end
      @items[0].stubs(:[]).with(:created_at).returns('23-02-2009')
      @items[1].stubs(:[]).with(:created_at).returns('22-03-2009')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed
      assert_match(
        Regexp.new('Article 1.*Article 0', Regexp::MULTILINE),
        result,
      )
    end
  end

  def test_atom_feed_preserve_order
    if_have 'builder' do
      # Mock articles
      @items = [mock_article, mock_article]
      @items.each_with_index do |article, i|
        article.stubs(:[]).with(:title).returns("Article #{i}")
      end
      @items[0].stubs(:[]).with(:created_at).returns('01-01-2015')
      @items[1].stubs(:[]).with(:created_at).returns('01-01-2014')

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed(preserve_order: true)
      assert_match(
        Regexp.new('Article 1.*Article 0', Regexp::MULTILINE),
        result,
      )
    end
  end

  def test_atom_feed_with_content_proc_param
    if_have 'builder' do
      # Mock article
      @items = [mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed content_proc: ->(_a) { 'foobar!' }
      assert_match 'foobar!</content>', result
    end
  end

  def test_atom_feed_with_excerpt_proc_param
    if_have 'builder' do
      # Mock article
      @items = [mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed excerpt_proc: ->(_a) { 'foobar!' }
      assert_match 'foobar!</summary>', result
    end
  end

  def test_atom_feed_with_icon_param
    if_have 'builder' do
      # Mock article
      @items = [mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed icon: 'http://example.com/icon.png'
      assert_match '<icon>http://example.com/icon.png</icon>', result
    end
  end

  def test_atom_feed_with_logo_param
    if_have 'builder' do
      # Mock article
      @items = [mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed logo: 'http://example.com/logo.png'
      assert_match '<logo>http://example.com/logo.png</logo>', result
    end
  end

  def test_atom_feed_with_xml_base
    if_have 'builder' do
      # Mock article
      @items = [mock_article]

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed
      assert_match 'xml:base="http://example.com/"', result
    end
  end

  def test_atom_feed_with_item_without_path
    if_have 'builder' do
      # Create items
      @items = [mock_article]
      @items[0].stubs(:path).returns(nil)

      # Mock site
      config = Nanoc::Int::Configuration.new(hash: { base_url: 'http://example.com' })
      @config = Nanoc::ConfigView.new(config, @view_context)

      # Create feed item
      @item = mock
      @item.stubs(:identifier).returns('/feed/')
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns('/journal/feed/')

      # Check
      atom_feed
    end
  end
end
