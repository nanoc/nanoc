# encoding: utf-8

module Nanoc3::Helpers

  # Nanoc3::Helpers::XMLSitemap contains functionality for building XML
  # sitemaps that will be crawled by search engines. See the Sitemaps protocol
  # web site, http://www.sitemaps.org, for details.
  #
  # To activate this helper, +include+ it, like this:
  #
  #   include Nanoc3::Helpers::XMLSitemap
  module XMLSitemap

    # Returns the XML sitemap as a string.
    #
    # The following attributes can optionally be set on items to change the
    # behaviour of the sitemap:
    #
    # * 'changefreq', containing the estimated change frequency as defined by
    #   the Sitemaps protocol.
    #
    # * 'priority', containing the item's priority, ranging from 0.0 to 1.0,
    #   as defined by the Sitemaps protocol.
    #
    # The sitemap will also include dates on which the items were updated.
    # These are generated automatically; the way this happens depends on the
    # used data source (the filesystem data source checks the file mtimes, for
    # instance).
    #
    # The site configuration will need to have the following attributes:
    #
    # * 'base_url', containing the URL to the site, without trailing slash.
    #   For example, if the site is at "http://example.com/", the base_url
    #   would be "http://example.com".
    def xml_sitemap
      require 'builder'

      # Create builder
      buffer = ''
      xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)

      # Check for required attributes
      if @site.config[:base_url].nil?
        raise RuntimeError.new("The Nanoc3::Helpers::XMLSitemap helper requires the site configuration to specify the base URL for the site.")
      end

      # Build sitemap
      xml.instruct!
      xml.urlset(:xmlns => 'http://www.google.com/schemas/sitemap/0.84') do
        # Add item
        @items.reject { |i| i[:is_hidden] || i[:skip_output] }.each do |item|
          # FIXME repeat this for every rep
          xml.url do
            xml.loc         @site.config[:base_url] + item.reps[0].path
            xml.lastmod     item.mtime.to_iso8601_date unless item.mtime.nil?
            xml.changefreq  item[:changefreq] unless item[:changefreq].nil?
            xml.priority    item[:priority] unless item[:priority].nil?
          end
        end
      end

      # Return sitemap
      buffer
    end

  end

end
