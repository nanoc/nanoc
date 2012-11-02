# encoding: utf-8

class Nanoc::Helpers::XMLSitemapTest < MiniTest::Unit::TestCase

  include Nanoc::TestHelpers

  include Nanoc::Helpers::XMLSitemap

  def teardown
    @items = nil
    @item  = nil
    @site  = nil
  end

  def test_xml_sitemap
    if_have 'builder', 'nokogiri' do
      # Create items
      @items = []

      # Create item 1
      @items << Nanoc::Item.new('some content 1', {}, '/item-one/')
      self.create_item_rep(@items.last, :one_a, '/item-one/a/')
      self.create_item_rep(@items.last, :one_b, '/item-one/b/')

      # Create item 2
      @items << Nanoc::Item.new('some content 2', { :is_hidden => true }, '/item-two/')

      # Create item 3
      attrs = { :mtime => Time.parse('12/07/2004'), :changefreq => 'daily', :priority => 0.5 }
      @items << Nanoc::Item.new('some content 3', attrs, '/item-three/')
      self.create_item_rep(@items.last, :three_a, '/item-three/a/')
      self.create_item_rep(@items.last, :three_b, '/item-three/b/')

      # Create item 4
      @items << Nanoc::Item.new('some content 4', {}, '/item-four/')
      self.create_item_rep(@items.last, :four_a, nil)

      # Create sitemap item
      @item = Nanoc::Item.new('sitemap content', {}, '/sitemap/')

      # Create site
      @site = Nanoc::Site.new({ :base_url => 'http://example.com' })

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
      assert_equal '2004-07-12',                       urls[2].css('> lastmod').inner_text
      assert_equal '2004-07-12',                       urls[3].css('> lastmod').inner_text
    end
  end

  def test_sitemap_with_items_as_param
    if_have 'builder', 'nokogiri' do
      # Create items
      @items = []
      @items << nil
      @items << Nanoc::Item.new('some content 1', {}, '/item-one/')
      self.create_item_rep(@items.last, :one_a, '/item-one/a/')
      self.create_item_rep(@items.last, :one_b, '/item-one/b/')
      @items << nil

      # Create sitemap item
      @item = Nanoc::Item.new('sitemap content', {}, '/sitemap/')

      # Create site
      @site = Nanoc::Site.new({ :base_url => 'http://example.com' })

      # Build sitemap
      res = xml_sitemap(:items => [ @items[1] ])

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

protected

  def create_item_rep(item, name, path)
    rep = Nanoc::ItemRep.new(item, name)
    rep.paths     = { :last => path }
    rep.raw_paths = { :last => path }
    item.reps << rep
    rep
  end

end
