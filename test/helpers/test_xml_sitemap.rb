class Nanoc::Helpers::XMLSitemapTest < Nanoc::TestCase
  include Nanoc::Helpers::XMLSitemap

  def setup
    super

    @reps = Nanoc::Int::ItemRepRepo.new
    dependency_tracker = Nanoc::Int::DependencyTracker.new(nil)
    @view_context = Nanoc::ViewContext.new(reps: @reps, items: nil, dependency_tracker: dependency_tracker, compilation_context: :__irrelevant__)

    @items = nil
    @item = nil
    @site = nil
    @config = nil
  end

  def test_xml_sitemap
    if_have 'builder', 'nokogiri' do
      # Create items
      @items = Nanoc::Int::IdentifiableCollection.new({})

      # Create item 1
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 1', {}, '/item-one/'), @view_context)
      @items << item
      create_item_rep(item.unwrap, :one_a, '/item-one/a/')
      create_item_rep(item.unwrap, :one_b, '/item-one/b/')

      # Create item 2
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 2', { is_hidden: true }, '/item-two/'), @view_context)
      @items << item

      # Create item 3
      attrs = { mtime: Time.parse('2004-07-12 00:00:00 +02:00'), changefreq: 'daily', priority: 0.5 }
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 3', attrs, '/item-three/'), @view_context)
      @items << item
      create_item_rep(item.unwrap, :three_a, '/item-three/a/')
      create_item_rep(item.unwrap, :three_b, '/item-three/b/')

      # Create item 4
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 4', {}, '/item-four/'), @view_context)
      @items << item
      create_item_rep(item.unwrap, :four_a, nil)

      # Create sitemap item
      @item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('sitemap content', {}, '/sitemap/'), @view_context)

      # Create site
      @config = Nanoc::ConfigView.new({ base_url: 'http://example.com' }, nil)

      # Build sitemap
      res = xml_sitemap

      # Check
      doc = Nokogiri::XML(res)
      urlsets = doc.css('> urlset')
      assert_equal 1, urlsets.size
      urls = urlsets.css('> url')
      assert_equal 4, urls.size
      assert_equal 'http://example.com/item-one/a/',   urls[0].css('> loc').inner_text
      assert_equal 'http://example.com/item-one/b/',   urls[1].css('> loc').inner_text
      assert_equal 'http://example.com/item-three/a/', urls[2].css('> loc').inner_text
      assert_equal 'http://example.com/item-three/b/', urls[3].css('> loc').inner_text
      assert_equal '',                                 urls[0].css('> changefreq').inner_text
      assert_equal '',                                 urls[1].css('> changefreq').inner_text
      assert_equal 'daily',                            urls[2].css('> changefreq').inner_text
      assert_equal 'daily',                            urls[3].css('> changefreq').inner_text
      assert_equal '',                                 urls[0].css('> priority').inner_text
      assert_equal '',                                 urls[1].css('> priority').inner_text
      assert_equal '0.5',                              urls[2].css('> priority').inner_text
      assert_equal '0.5',                              urls[3].css('> priority').inner_text
      assert_equal '',                                 urls[0].css('> lastmod').inner_text
      assert_equal '',                                 urls[1].css('> lastmod').inner_text
      assert_equal '2004-07-11',                       urls[2].css('> lastmod').inner_text
      assert_equal '2004-07-11',                       urls[3].css('> lastmod').inner_text
    end
  end

  def test_sitemap_with_items_as_param
    if_have 'builder', 'nokogiri' do
      # Create items
      @items = Nanoc::Int::IdentifiableCollection.new({})
      @items << nil
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 1', {}, '/item-one/'), @view_context)
      @items << item
      create_item_rep(item.unwrap, :one_a, '/item-one/a/')
      create_item_rep(item.unwrap, :one_b, '/item-one/b/')
      @items << nil

      # Create sitemap item
      @item = Nanoc::Int::Item.new('sitemap content', {}, '/sitemap/')

      # Create site
      @config = Nanoc::ConfigView.new({ base_url: 'http://example.com' }, nil)

      # Build sitemap
      res = xml_sitemap(items: [item])

      # Check
      doc = Nokogiri::XML(res)
      urlsets = doc.css('> urlset')
      assert_equal 1, urlsets.size
      urls = urlsets.css('> url')
      assert_equal 2, urls.size
      assert_equal 'http://example.com/item-one/a/',   urls[0].css('> loc').inner_text
      assert_equal 'http://example.com/item-one/b/',   urls[1].css('> loc').inner_text
      assert_equal '',                                 urls[0].css('> changefreq').inner_text
      assert_equal '',                                 urls[1].css('> changefreq').inner_text
      assert_equal '',                                 urls[0].css('> priority').inner_text
      assert_equal '',                                 urls[1].css('> priority').inner_text
      assert_equal '',                                 urls[0].css('> lastmod').inner_text
      assert_equal '',                                 urls[1].css('> lastmod').inner_text
    end
  end

  def test_filter
    if_have 'builder', 'nokogiri' do
      # Create items
      @items = Nanoc::Int::IdentifiableCollection.new({})
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 1', {}, '/item-one/'), @view_context)
      @items << item
      create_item_rep(item.unwrap, :one_a, '/item-one/a/')
      create_item_rep(item.unwrap, :one_b, '/item-one/b/')

      # Create sitemap item
      @item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('sitemap content', {}, '/sitemap/'), @view_context)

      # Create site
      @config = Nanoc::ConfigView.new({ base_url: 'http://example.com' }, nil)

      # Build sitemap
      res = xml_sitemap(rep_select: ->(rep) { rep.name == :one_a })

      # Check
      doc = Nokogiri::XML(res)
      urlsets = doc.css('> urlset')
      assert_equal 1, urlsets.size
      urls = urlsets.css('> url')
      assert_equal 1, urls.size
      assert_equal 'http://example.com/item-one/a/',   urls[0].css('> loc').inner_text
      assert_equal '',                                 urls[0].css('> changefreq').inner_text
      assert_equal '',                                 urls[0].css('> priority').inner_text
      assert_equal '',                                 urls[0].css('> lastmod').inner_text
    end
  end

  def test_sorted
    if_have 'builder', 'nokogiri' do
      # Create items
      @items = Nanoc::Int::IdentifiableCollection.new({})
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 1', {}, '/george/'), @view_context)
      @items << item
      create_item_rep(item.unwrap, :a_alice,   '/george/alice/')
      create_item_rep(item.unwrap, :b_zoey,    '/george/zoey/')
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 1', {}, '/walton/'), @view_context)
      @items << item
      create_item_rep(item.unwrap, :a_eve,     '/walton/eve/')
      create_item_rep(item.unwrap, :b_bob,     '/walton/bob/')
      item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('some content 1', {}, '/lucas/'), @view_context)
      @items << item
      create_item_rep(item.unwrap, :a_trudy,   '/lucas/trudy/')
      create_item_rep(item.unwrap, :b_mallory, '/lucas/mallory/')

      # Create sitemap item
      @item = Nanoc::ItemWithRepsView.new(Nanoc::Int::Item.new('sitemap content', {}, '/sitemap/'), @view_context)

      # Create site
      @config = Nanoc::ConfigView.new({ base_url: 'http://example.com' }, nil)

      # Build sitemap
      res = xml_sitemap(items: @items)

      # Check
      doc = Nokogiri::XML(res)
      urlsets = doc.css('> urlset')
      assert_equal 1, urlsets.size
      urls = urlsets.css('> url')
      assert_equal 6, urls.size
      assert_equal 'http://example.com/george/alice/',  urls[0].css('> loc').inner_text
      assert_equal 'http://example.com/george/zoey/',   urls[1].css('> loc').inner_text
      assert_equal 'http://example.com/lucas/trudy/',   urls[2].css('> loc').inner_text
      assert_equal 'http://example.com/lucas/mallory/', urls[3].css('> loc').inner_text
      assert_equal 'http://example.com/walton/eve/',    urls[4].css('> loc').inner_text
      assert_equal 'http://example.com/walton/bob/',    urls[5].css('> loc').inner_text
    end
  end

  protected

  def create_item_rep(item, name, path)
    rep = Nanoc::Int::ItemRep.new(item, name)
    rep.paths     = { last: path }
    rep.raw_paths = { last: path }
    @reps << rep
    rep
  end
end
