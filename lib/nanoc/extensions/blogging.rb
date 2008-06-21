class Time

  # Returns a string with the time in an ISO-8601 date format.
  def to_iso8601_date
    self.strftime("%Y-%m-%d")
  end

  # Returns a string with the time in an ISO-8601 time format.
  def to_iso8601_time
    self.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")
  end

end

module Nanoc::Extensions

  # Nanoc::Extensions::Blogging provides some functionality for building
  # blogs, such as finding articles and constructing feeds.
  #
  # This extension has a few requirements. First, all blog articles should
  # have the following attributes:
  #
  # * 'kind', set to 'article'.
  #
  # * 'created_at', set to the creation timestamp.
  #
  # Some functions in this blogging extension, such as the +atom_feed+
  # function, require additional attributes to be set; these attributes are
  # described in the documentation for these functions.
  #
  # The two main functions are sorted_articles and atom_feed.
  module Blogging

    # Returns the list of articles, sorted by descending creation date (so
    # newer articles appear first).
    def sorted_articles
      @pages.select do |page|
        page.kind == 'article'
      end.sort do |x,y|
        y.created_at <=> x.created_at
      end
    end

    # Returns a string representing the atom feed containing recent articles,
    # sorted by descending creation date. +params+ is a hash where the
    # following keys can be set:
    #
    # +limit+:: The maximum number of articles to show. Defaults to 5.
    #
    # The following attributes can optionally be set on blog articles to
    # change the behaviour of the Atom feed:
    #
    # * 'excerpt', containing an excerpt of the article, usually only a few
    #   lines long.
    #
    # * 'custom_path_in_feed', containing the path that will be used instead
    #   of the normal path in the feed. This can be useful when including
    #   non-outputted pages in a feed; such pages could have their custom feed
    #   path set to the blog path instead, for example.
    #
    # The feed will also include dates on which the articles were updated.
    # These are generated automatically; the way this happens depends on the
    # used data source (the filesystem data source checks the file mtimes, for
    # instance).
    #
    # The feed page will need to have the following attributes:
    #
    # * 'base_url', containing the URL to the site, without trailing slash.
    #   For example, if the site is at "http://example.com/", the base_url
    #   would be "http://example.com". It is probably a good idea to define
    #   this in the page defaults, i.e. the 'meta.yaml' file (at least if the
    #   filesystem data source is being used, which is probably the case).
    #
    # * 'title', containing the title of the feed, which is usually also the
    #   title of the blog.
    #
    # * 'author_name', containing the name of the page's author. This will
    #   likely be a global attribute, unless the site is managed by several
    #   people/
    #
    # * 'author_uri', containing the URI for the page's author, such as the
    #   author's web site URL. This will also likely be a global attribute.
    #
    # The feed page can have the following optional attributes:
    #
    # * 'feed_url', containing the custom URL of the feed. This can be useful
    #   when the private feed URL shouldn't be exposed; for example, when
    #   using FeedBurner this would be set to the public FeedBurner URL.
    #
    # To construct a feed, create a blank page with no layout, only the 'erb'
    # (or 'erubis') filter, and an 'xml' extension. It may also be useful to
    # set 'is_hidden' to true, so that extensions such as the sitemap
    # extension will ignore the page. The content of the feed page should be:
    #
    #   <%= atom_feed %>
    def atom_feed(params={})
      require 'builder'

      # Extract parameters
      limit = params[:limit] || 5

      # Get most recent article
      last_article = sorted_articles.first

      # Create builder
      buffer = ''
      xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)

      # Build feed
      xml.instruct!
      xml.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
        # Add primary attributes
        xml.id      @page.base_url + '/'
        xml.title   @page.title

        # Add date
        xml.updated last_article.created_at.to_iso8601_time

        # Add links
        xml.link(:rel => 'alternate', :href => @page.base_url)
        xml.link(:rel => 'self',      :href => feed_url)

        # Add author information
        xml.author do
          xml.name  @page.author_name
          xml.uri   @page.author_uri
        end

        # Add articles
        sorted_articles.first(limit).each do |a|
          xml.entry do
            # Add primary attributes
            xml.id        atom_tag_for(a)
            xml.title     a.title, :type => 'html'

            # Add dates
            xml.published a.created_at.to_iso8601_time
            xml.updated   a.mtime.to_iso8601_time

            # Add link
            xml.link(:rel => 'alternate', :href => url_for(a))

            # Add content
            xml.content   a.content, :type => 'html'
            xml.summary   a.excerpt, :type => 'html' unless a.excerpt.nil?
          end
        end
      end

      buffer
    end

    # Returns the URL for the given page. It will return the URL containing
    # the custom path in the feed if possible, otherwise the normal path.
    def url_for(page)
      @page.base_url + (page.custom_path_in_feed || page.path)
    end

    # Returns the URL of the feed. It will return the custom feed URL if set,
    # or otherwise the normal feed URL.
    def feed_url
      @page.feed_url || @page.base_url + @page.path
    end

    # Returns an URI containing an unique ID for the given page. This will be
    # used in the Atom feed to uniquely identify articles. These IDs are
    # created using a procedure suggested by Mark Pilgrim in this blog post:
    # http://diveintomark.org/archives/2004/05/28/howto-atom-id.
    def atom_tag_for(page)
      hostname        = @page.base_url.sub(/.*:\/\/(.+?)\/?$/, '\1')
      formatted_date  = page.created_at.to_iso8601_date

      'tag:' + hostname + ',' + formatted_date + ':' + page.path
    end

  end

end
