# frozen_string_literal: true

require 'helper'

class Nanoc::Helpers::XMLSitemapTest < Nanoc::TestCase
  include Nanoc::Helpers::XMLSitemap

  def setup
    super

    config = Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults
    items = Nanoc::Core::ItemCollection.new(config)
    layouts = Nanoc::Core::LayoutCollection.new(config)
    dep_store = Nanoc::Core::DependencyStore.new(items, layouts, config)
    dependency_tracker = Nanoc::Core::DependencyTracker.new(dep_store)
    @reps = Nanoc::Core::ItemRepRepo.new

    site =
      Nanoc::Core::Site.new(
        config:,
        code_snippets: [],
        data_source: Nanoc::Core::InMemoryDataSource.new(items, layouts),
      )

    compiled_content_cache = Nanoc::Core::CompiledContentCache.new(config:)
    compiled_content_store = Nanoc::Core::CompiledContentStore.new

    action_provider =
      Class.new(Nanoc::Core::ActionProvider) do
        def self.for(_context)
          raise NotImplementedError
        end

        def initialize; end
      end.new

    compilation_context =
      Nanoc::Core::CompilationContext.new(
        action_provider:,
        reps: @reps,
        site:,
        compiled_content_cache:,
        compiled_content_store:,
      )

    @view_context = Nanoc::Core::ViewContextForCompilation.new(
      reps: @reps,
      items: Nanoc::Core::ItemCollection.new(config),
      dependency_tracker:,
      compilation_context:,
      compiled_content_store: Nanoc::Core::CompiledContentStore.new,
    )

    @items = nil
    @item = nil
    @site = nil
    @config = nil
  end

  def test_xml_sitemap
    if_have 'nokogiri' do
      # Create items
      items = []

      # Create item 1
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 1', {}, '/item-one'), @view_context)
      items << item
      create_item_rep(item._unwrap, :one_a, '/item-one/a/')
      create_item_rep(item._unwrap, :one_b, '/item-one/b/')

      # Create item 2
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 2', { is_hidden: true }, '/item-two'), @view_context)
      items << item

      # Create item 3
      attrs = { mtime: Time.parse('2004-07-12 00:00:00 +02:00'), changefreq: 'daily', priority: 0.5 }
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 3', attrs, '/item-three'), @view_context)
      items << item
      create_item_rep(item._unwrap, :three_a, '/item-three/a/')
      create_item_rep(item._unwrap, :three_b, '/item-three/b/')

      # Create item 4
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 4', {}, '/item-four'), @view_context)
      items << item
      create_item_rep(item._unwrap, :four_a, nil)

      # Create items
      @items = Nanoc::Core::ItemCollection.new({}, items)

      # Create sitemap item
      @item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('sitemap content', {}, '/sitemap'), @view_context)

      # Create site
      config = Nanoc::Core::Configuration.new(hash: { base_url: 'http://example.com' }, dir: Dir.getwd)
      @config = Nanoc::Core::ConfigView.new(config, @view_context)

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
    if_have 'nokogiri' do
      # Create items
      items = []
      items << nil
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 1', {}, '/item-one'), @view_context)
      items << item
      create_item_rep(item._unwrap, :one_a, '/item-one/a/')
      create_item_rep(item._unwrap, :one_b, '/item-one/b/')
      items << nil
      @items = Nanoc::Core::ItemCollection.new({})

      # Create sitemap item
      @item = Nanoc::Core::Item.new('sitemap content', {}, '/sitemap')

      # Create site
      config = Nanoc::Core::Configuration.new(hash: { base_url: 'http://example.com' }, dir: Dir.getwd)
      @config = Nanoc::Core::ConfigView.new(config, @view_context)

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
    if_have 'nokogiri' do
      # Create items
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 1', {}, '/item-one'), @view_context)
      @items = Nanoc::Core::ItemCollection.new({}, [item])
      create_item_rep(item._unwrap, :one_a, '/item-one/a/')
      create_item_rep(item._unwrap, :one_b, '/item-one/b/')

      # Create sitemap item
      @item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('sitemap content', {}, '/sitemap'), @view_context)

      # Create site
      config = Nanoc::Core::Configuration.new(hash: { base_url: 'http://example.com' }, dir: Dir.getwd)
      @config = Nanoc::Core::ConfigView.new(config, @view_context)

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
    if_have 'nokogiri' do
      # Create items
      items = []
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 1', {}, '/george'), @view_context)
      items << item
      create_item_rep(item._unwrap, :a_alice,   '/george/alice/')
      create_item_rep(item._unwrap, :b_zoey,    '/george/zoey/')
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 1', {}, '/walton'), @view_context)
      items << item
      create_item_rep(item._unwrap, :a_eve,     '/walton/eve/')
      create_item_rep(item._unwrap, :b_bob,     '/walton/bob/')
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 1', {}, '/lucas'), @view_context)
      items << item
      create_item_rep(item._unwrap, :a_trudy,   '/lucas/trudy/')
      create_item_rep(item._unwrap, :b_mallory, '/lucas/mallory/')
      @items = Nanoc::Core::ItemCollection.new({}, items)

      # Create sitemap item
      @item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('sitemap content', {}, '/sitemap'), @view_context)

      # Create site
      config = Nanoc::Core::Configuration.new(hash: { base_url: 'http://example.com' }, dir: Dir.getwd)
      @config = Nanoc::Core::ConfigView.new(config, @view_context)

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

  def test_url_escape
    if_have 'nokogiri' do
      # Create items
      item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('some content 1', {}, '/george'), @view_context)
      @items = Nanoc::Core::ItemCollection.new({}, [item])
      create_item_rep(item._unwrap, :default, '/cool projects/проверка')

      # Create sitemap item
      @item = Nanoc::Core::CompilationItemView.new(Nanoc::Core::Item.new('sitemap content', {}, '/sitemap'), @view_context)

      # Create site
      config = Nanoc::Core::Configuration.new(hash: { base_url: 'http://example.com' }, dir: Dir.getwd)
      @config = Nanoc::Core::ConfigView.new(config, @view_context)

      # Build sitemap
      res = xml_sitemap(items: @items)

      # Check
      doc = Nokogiri::XML(res)
      urlsets = doc.css('> urlset')

      assert_equal 1, urlsets.size
      urls = urlsets.css('> url')

      assert_equal 1, urls.size
      assert_equal 'http://example.com/cool%20projects/%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0', urls[0].css('> loc').inner_text
    end
  end

  protected

  def create_item_rep(item, name, path)
    rep = Nanoc::Core::ItemRep.new(item, name)
    rep.paths     = { last: (path ? [path] : []) }
    rep.raw_paths = { last: (path ? [path] : []) }
    @reps << rep
    rep
  end
end
