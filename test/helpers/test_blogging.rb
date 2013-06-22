# encoding: utf-8

class Nanoc::Helpers::BloggingTest < Nanoc::TestCase

  include Nanoc::Helpers::Blogging
  include Nanoc::Helpers::Text

  def setup
    super
    @snapshot_store = Nanoc::SnapshotStore::InMemory.new
  end

  def teardown
    super
    @items = nil
    @item = nil
    @site = nil
  end

  def mock_site(config)
    in_site do
      File.write('nanoc.yaml', YAML.dump(config))
      return Nanoc::SiteLoader.new.load
    end
  end

  def mock_article(custom_attrs={})
    attrs = {
      :updated_at          => Time.now - 500,
      :kind                => 'article',
      :created_at          => Time.now - 1000,
      :title               => 'An Item',
      :custom_path_in_feed => nil,
      :custom_url_in_feed  => nil,
      :excerpt             => nil,
      :author_name         => nil,
      :author_uri          => nil,
    }.merge(custom_attrs)
    item = Nanoc::Item.new('item content', attrs, '/article/')
    item.stubs(:path).returns('/meow.html')
    item.stubs(:compiled_content).returns('stuff')
    item
  end

  def mock_item
    Nanoc::Item.new('item content', { :kind => 'item' }, '/item/')
  end

  def mock_feed_item(custom_attrs={})
    attrs = {
      :title       => 'My Cool Blog',
      :author_name => 'Denis Defreyne',
      :author_uri  => 'http://stoneship.org/',
      :feed_uri    => nil,
    }.merge(custom_attrs)
    @item = Nanoc::Item.new('content stuff', attrs, '/feed.xml')
    @item.stubs(:path).returns("/journal/feed/")
    @item
  end

  def test_articles
    # Create items
    @items = [
      Nanoc::Item.new('blah',           { :kind => 'item'    }, '/0/'),
      Nanoc::Item.new('blah blah',      { :kind => 'article' }, '/1/'),
      Nanoc::Item.new('blah blah blah', { :kind => 'article' }, '/2/')
    ]

    # Check
    assert_equal(2, articles.size)
    assert articles.include?(@items[1])
    assert articles.include?(@items[2])
  end

  def test_sorted_articles
    # Create items
    @items = [
      Nanoc::Item.new(
        'blah',
        { :kind => 'item' },
        '/0/'
      ),
      Nanoc::Item.new(
        'blah',
        { :kind => 'article', :created_at => (Date.today - 1).to_s },
        '/1/'
      ),
      Nanoc::Item.new(
        'blah',
        { :kind => 'article', :created_at => (Time.now - 500).to_s },
        '/2/'
      )
    ]

    # Check
    assert_equal(2,         sorted_articles.size)
    assert_equal(@items[2], sorted_articles[0])
    assert_equal(@items[1], sorted_articles[1])
  end

  def test_atom_feed
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article, mock_article ]

      # Mock paths and compiled content
      @items[1].stubs(:path).returns("/item1/")
      @items[1].expects(:compiled_content).with(:snapshot => :pre).returns('item 1 content')
      @items[2].expects(:compiled_content).with(:snapshot => :pre).returns('item 2 content')

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      atom_feed
    end
  end

  def test_atom_feed_with_times
    if_have 'builder' do
      # Create items
      @items = [
        mock_item,
        mock_article({
          :updated_at => Time.now - 500,
          :created_at => Time.now - 1000,
          }),
        mock_article({
          :updated_at => Time.now - 250,
          :created_at => Time.now - 1200,
          })
      ]
      @items[1].stubs(:compiled_content).returns('item 1 content')
      @items[2].stubs(:compiled_content).returns('item 2 content')

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      atom_feed
    end
  end

  def test_atom_feed_without_articles
    if_have 'builder' do
      # Mock items
      @items = [ mock_item, mock_item ]

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      error = assert_raises(Nanoc::Errors::GenericTrivial) do
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
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => nil })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      error = assert_raises(Nanoc::Errors::GenericTrivial) do
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
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item(:title => nil)

      # Check
      error = assert_raises(Nanoc::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no title in params, item or site config',
        error.message
      )
    end
  end

  def test_atom_feed_without_author_name
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item(:author_name => nil)

      # Check
      error = assert_raises(Nanoc::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no author_name in params, item or site config',
        error.message
      )
    end
  end

  def test_atom_feed_with_author_name_and_uri_from_content_item
    if_have 'builder' do
      # Create items
      @items = [
        mock_article({
          :author_name => "Don Alias",
          :author_uri  => "http://don.example.com/"
        })
      ]
      @items[0].stubs(:compiled_content).returns('item 1 content')
      @items[0].stubs(:path).returns('/something')

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com/' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      # TODO: Use xpath matchers for more specific test
      result = atom_feed
      assert_match(%r{<name>Denis Defreyne</name>},        result)
      assert_match(%r{<uri>http://stoneship.org/</uri>},   result)
      assert_match(%r{<name>Don Alias</name>},             result)
      assert_match(%r{<uri>http://don.example.com/</uri>}, result)
    end
  end

  def test_atom_feed_without_author_uri
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item(:author_uri => nil)

      # Check
      error = assert_raises(Nanoc::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: no author_uri in params, item or site config',
        error.message
      )
    end
  end

  def test_atom_feed_without_articles_created_at
    if_have 'builder' do
      # Create items
      @items = [
        mock_item,
        mock_article({ :created_at => Time.now.to_s }),
        mock_article({ :created_at => nil }),
      ]

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      error = assert_raises(Nanoc::Errors::GenericTrivial) do
        atom_feed
      end
      assert_equal(
        'Cannot build Atom feed: one or more articles lack created_at',
        error.message
      )
    end
  end

  def test_atom_feed_with_title_author_name_and_uri_as_params
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns(nil)
      @item.stubs(:[]).with(:author_name).returns(nil)
      @item.stubs(:[]).with(:author_uri).returns(nil)
      @item.stubs(:[]).with(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      atom_feed(
        :author_name => 'Bob',
        :author_uri  => 'http://example.com/~bob/',
        :title       => 'My Blog Or Something'
      )
    end
  end

  def test_atom_feed_with_title_author_name_and_uri_from_config
    if_have 'builder' do
      # Create items
      @items = [ mock_item, mock_article ]

      # Mock site
      @config = {
        :author_name => 'Bob',
        :author_uri  => 'http://example.com/~bob/',
        :title       => 'My Blog Or Something',
        :base_url    => 'http://example.com'
      }
      @site = mock_site(@config)

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
      @items = [
        mock_article,
        mock_article({ :title => 'Item One' }),
      ]
      @items[1].expects(:compiled_content).with(:snapshot => :pre).returns('asdf')

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      atom_feed :articles => [ @items[1] ]
    end
  end

  def test_atom_feed_with_limit_param
    if_have 'builder' do
      # Mock articles
      @items = [
        mock_article({ :title => "Article 0", :created_at => Time.now }),
        mock_article({ :title => "Article 1", :created_at => Time.now - 1 }),
      ]

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      result = atom_feed :limit => 1, :articles => @items
      assert_match(Regexp.new('Article 0', Regexp::MULTILINE), result)
      refute_match(Regexp.new('Article 1', Regexp::MULTILINE), result)
    end
  end

  def test_atom_feed_sorting
    if_have 'builder' do
      # Mock articles
      @items = [
        mock_article({ :title => "Article 0", :created_at => '22-02-2009' }),
        mock_article({ :title => "Article 1", :created_at => '22-02-2009' }),
      ]
      @items[0].stubs(:identifier).returns("/article-0.html")
      @items[1].stubs(:identifier).returns("/article-1.html")

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      assert_equal [ @items[1], @items[0] ], sorted_articles
      result = atom_feed
      assert_match(
        Regexp.new('Article 1.*Article 0', Regexp::MULTILINE),
        result
      )
    end
  end

  def test_atom_feed_with_content_proc_param
    if_have 'builder' do
      # Mock article
      @items = [ mock_article ]

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      result = atom_feed :content_proc => lambda { |a| 'foobar!' }
      assert_match 'foobar!</content>', result
    end
  end

  def test_atom_feed_with_excerpt_proc_param
    if_have 'builder' do
      # Mock article
      @items = [ mock_article ]

      # Mock site
      @site = mock
      @site.stubs(:config).returns({ :base_url => 'http://example.com' })

      # Create feed item
      @item = self.mock_feed_item

      # Check
      result = atom_feed :excerpt_proc => lambda { |a| 'foobar!' }
      assert_match 'foobar!</summary>', result
    end
  end

  def test_atom_feed_with_icon_param
    if_have 'builder' do
      # Mock article
      @items = [ mock_article ]

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
      result = atom_feed :icon => 'http://example.com/icon.png'
      assert_match '<icon>http://example.com/icon.png</icon>', result
    end
  end

  def test_atom_feed_with_logo_param
    if_have 'builder' do
      # Mock article
      @items = [ mock_article ]

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:[]).with(:title).returns('My Blog Or Something')
      @item.stubs(:[]).with(:author_name).returns('J. Doe')
      @item.stubs(:[]).with(:author_uri).returns('http://example.com/~jdoe')
      @item.stubs(:[]).with(:feed_url).returns('http://example.com/feed')

      # Check
      result = atom_feed :logo => 'http://example.com/logo.png'
      assert_match '<logo>http://example.com/logo.png</logo>', result
    end
  end

  def test_atom_feed_with_item_without_path
    if_have 'builder' do
      # Create items
      @items = [ mock_article ]
      @items[0].stubs(:path).returns(nil)

      # Mock site
      @site = mock_site({ :base_url => 'http://example.com' })

      # Create feed item
      @item = mock
      @item.stubs(:identifier).returns('/feed/')
      @item.stubs(:[]).with(:title).returns('My Cool Blog')
      @item.stubs(:[]).with(:author_name).returns('Denis Defreyne')
      @item.stubs(:[]).with(:author_uri).returns('http://stoneship.org/')
      @item.stubs(:[]).with(:feed_url).returns(nil)
      @item.stubs(:path).returns("/journal/feed/")

      # Check
      atom_feed
    end
  end

  def test_url_for_without_custom_path_in_feed
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', {}, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    rep.paths = { :last => '/foo/bar/' }
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('http://example.com/foo/bar/', url_for(@item))
  end

  def test_url_for_with_custom_path_in_feed
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', { :custom_path_in_feed => '/meow/woof/' }, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('http://example.com/meow/woof/', url_for(@item))
  end

  def test_url_for_with_custom_url_in_feed
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', { :custom_url_in_feed => 'http://example.org/x' }, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('http://example.org/x', url_for(@item))
  end

  def test_url_for_without_base_url
    # Create site
    @site = mock_site({})

    # Check
    assert_raises(Nanoc::Errors::GenericTrivial) do
      url_for(nil)
    end
  end

  def test_url_for_without_path
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', {}, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    rep.paths = {}
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal(nil, url_for(@item))
  end

  def test_feed_url_without_custom_feed_url
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', {}, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    rep.paths = { :last => '/foo/bar/' }
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('http://example.com/foo/bar/', feed_url)
  end

  def test_feed_url_with_custom_feed_url
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create feed item
    item = Nanoc::Item.new('content', { :feed_url => 'http://example.com/feed/' }, '/foo/')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    rep.paths = { :last => '/foo/bar/' }
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('http://example.com/feed/', feed_url)
  end

  def test_feed_url_without_base_url
    # Create site
    @site = mock_site({})

    # Check
    assert_raises(Nanoc::Errors::GenericTrivial) do
      feed_url
    end
  end

  def test_atom_tag_for_with_path
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', { :created_at => '2008-05-19' }, '/item-identifier.txt')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    rep.paths = { :last => '/rep-path.txt' }
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('tag:example.com,2008-05-19:/rep-path.txt', atom_tag_for(@item))
  end

  def test_atom_tag_for_without_path
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', { :created_at => '2008-05-19' }, '/item-identifier.txt')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('tag:example.com,2008-05-19:/item-identifier.txt', atom_tag_for(@item))
  end

  def test_atom_tag_for_with_base_url_in_dir
    # Create site
    @site = mock_site({ :base_url => 'http://example.com/somedir' })

    # Create article
    item = Nanoc::Item.new('content', { :created_at => '2008-05-19' }, '/item-identifier.txt')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    rep.paths = { :last => '/rep-path.txt' }
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('tag:example.com,2008-05-19:/somedir/rep-path.txt', atom_tag_for(@item))
  end

  def test_atom_tag_for_with_time
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', { :created_at => Time.parse('2008-05-19') }, '/item-identifier.txt')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    rep.paths = { :last => '/rep-path.txt' }
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('tag:example.com,2008-05-19:/rep-path.txt', atom_tag_for(@item))
  end

  def test_atom_tag_for_with_date
    # Create site
    @site = mock_site({ :base_url => 'http://example.com' })

    # Create article
    item = Nanoc::Item.new('content', { :created_at => Date.parse('2008-05-19') }, '/item-identifier.txt')
    rep = Nanoc::ItemRep.new(item, :default, :snapshot_store => @snapshot_store)
    rep.paths = { :last => '/rep-path.txt' }
    item_rep_store = Nanoc::ItemRepStore.new([ rep ])
    @item = Nanoc::ItemProxy.new(item, item_rep_store)

    # Check
    assert_equal('tag:example.com,2008-05-19:/rep-path.txt', atom_tag_for(@item))
  end

end
