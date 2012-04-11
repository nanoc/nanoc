# encoding: utf-8

module Nanoc::Helpers

  # Contains functionality for building XML sitemaps that will be crawled by
  # search engines. See the [Sitemaps protocol site](http://www.sitemaps.org)
  # for details.
  module XMLSitemap

    # Builds an XML sitemap and returns it.
    #
    # The following attributes can optionally be set on items to change the
    # behaviour of the sitemap:
    #
    # * `changefreq` — The estimated change frequency as defined by the
    #   Sitemaps protocol
    #
    # * `priority` — The item's priority, ranging from 0.0 to 1.0, as defined
    #   by the Sitemaps protocol
    #
    # The sitemap will also include dates on which the items were updated.
    # These are generated automatically; the way this happens depends on the
    # used data source (the filesystem data source checks the file mtimes, for
    # instance).
    #
    # The site configuration will need to have the following attributes:
    #
    # * `base_url` — The URL to the site, without trailing slash. For example,
    #   if the site is at "http://example.com/", the `base_url` would be
    #   "http://example.com".
    #
    # @example Excluding binary items from the sitemap
    #
    #   <%= xml_sitemap :items => @items.reject{ |i| i[:is_hidden] || i.binary? } %>
    #
    # @option params [Array] :items A list of items to include in the sitemap
    #
    # @return [String] The XML sitemap
    def xml_sitemap(params={})
      require 'builder'

      # Extract parameters
      items = params[:items] || @items.reject { |i| i[:is_hidden] }

      # Create builder
      buffer = ''
      xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)

      # Check for required attributes
      if @site.config[:base_url].nil?
        raise RuntimeError.new("The Nanoc::Helpers::XMLSitemap helper requires the site configuration to specify the base URL for the site.")
      end

      # Build sitemap
      xml.instruct!
      xml.urlset(:xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9') do
        # Add item
        items.each do |item|
          item.reps.reject { |r| r.raw_path.nil? }.each do |rep|
            xml.url do
              xml.loc         @site.config[:base_url] + rep.path
              xml.lastmod     item.mtime.to_iso8601_date unless item.mtime.nil?
              xml.changefreq  item[:changefreq] unless item[:changefreq].nil?
              xml.priority    item[:priority] unless item[:priority].nil?
            end
          end
        end
      end

      # Return sitemap
      buffer
    end

  end

end
