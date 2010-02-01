# encoding: utf-8

module Nanoc3::Helpers

  # Nanoc3::Helpers::Blogging provides some functionality for building blogs,
  # such as finding articles and constructing feeds.
  #
  # This helper has a few requirements. First, all blog articles should have
  # the following attributes:
  #
  # * 'kind', set to 'article'.
  #
  # * 'created_at', set to the creation timestamp.
  #
  # Some functions in this blogging helper, such as the +atom_feed+ function,
  # require additional attributes to be set; these attributes are described in
  # the documentation for these functions.
  #
  # The two main functions are sorted_articles and atom_feed.
  #
  # To activate this helper, +include+ it, like this:
  #
  #   include Nanoc3::Helpers::Blogging
  module Blogging

    # Returns an unsorted list of articles.
    def articles
      @items.select { |item| item[:kind] == 'article' }
    end

    # Returns a list of articles, sorted by descending creation date (so newer
    # articles appear first).
    def sorted_articles
      require 'time'
      articles.sort_by { |a| Time.parse(a[:created_at]) }.reverse
    end

    # Returns a string representing the atom feed containing recent articles,
    # sorted by descending creation date. +params+ is a hash where the
    # following keys can be set:
    #
    # +limit+:: The maximum number of articles to show. Defaults to 5.
    #
    # +articles+:: A list of articles to include in the feed. Defaults to the
    #              list of articles returned by the articles function.
    #
    # +content_proc+:: A proc that returns the content of the given article,
    #                  passed as a parameter. By default, given the argument
    #                  +article+, this proc will return
    #                  +article.reps[0].content+. This function may not return
    #                  nil.
    #
    # +excerpt_proc+:: A proc that returns the excerpt of the given article,
    #                  passed as a parameter. By default, given the argument
    #                  +article+, this proc will return +article.excerpt+.
    #                  This function may return nil.
    #
    # The following attributes must be set on blog articles:
    #
    # * 'title', containing the title of the blog post.
    #
    # * all other attributes mentioned above.
    #
    # The following attributes can optionally be set on blog articles to
    # change the behaviour of the Atom feed:
    #
    # * 'excerpt', containing an excerpt of the article, usually only a few
    #   lines long.
    #
    # * 'custom_path_in_feed', containing the path that will be used instead
    #   of the normal path in the feed. This can be useful when including
    #   non-outputted items in a feed; such items could have their custom feed
    #   path set to the blog path instead, for example.
    #
    # The feed will also include dates on which the articles were updated.
    # These are generated automatically; the way this happens depends on the
    # used data source (the filesystem data source checks the file mtimes, for
    # instance).
    #
    # The site configuration will need to have the following attributes:
    #
    # * 'base_url', containing the URL to the site, without trailing slash.
    #   For example, if the site is at "http://example.com/", the base_url
    #   would be "http://example.com".
    #
    # The feed item will need to have the following attributes:
    #
    # * 'title', containing the title of the feed, which is usually also the
    #   title of the blog.
    #
    # * 'author_name', containing the name of the item's author. This will
    #   likely be a global attribute, unless the site is managed by several
    #   people/
    #
    # * 'author_uri', containing the URI for the item's author, such as the
    #   author's web site URL. This will also likely be a global attribute.
    #
    # The feed item can have the following optional attributes:
    #
    # * 'feed_url', containing the custom URL of the feed. This can be useful
    #   when the private feed URL shouldn't be exposed; for example, when
    #   using FeedBurner this would be set to the public FeedBurner URL.
    #
    # To construct a feed, create a blank item with no layout, only the 'erb'
    # (or 'erubis') filter, and an 'xml' extension. It may also be useful to
    # set 'is_hidden' to true, so that helpers such as the sitemap helper will
    # ignore the item. The content of the feed item should be:
    #
    #   <%= atom_feed %>
    def atom_feed(params={})
      require 'builder'
      require 'time'

      # Extract parameters
      limit             = params[:limit] || 5
      relevant_articles = params[:articles] || articles || []
      content_proc      = params[:content_proc] || lambda { |a| a.reps[0].content_at_snapshot(:pre) }
      excerpt_proc      = params[:excerpt_proc] || lambda { |a| a[:excerpt] }

      # Check config attributes
      if @site.config[:base_url].nil?
        raise RuntimeError.new('Cannot build Atom feed: site configuration has no base_url')
      end

      # Check feed item attributes
      if @item[:title].nil?
        raise RuntimeError.new('Cannot build Atom feed: feed item has no title')
      end
      if @item[:author_name].nil?
        raise RuntimeError.new('Cannot build Atom feed: feed item has no author_name')
      end
      if @item[:author_uri].nil?
        raise RuntimeError.new('Cannot build Atom feed: feed item has no author_uri')
      end

      # Check article attributes
      if relevant_articles.empty?
        raise RuntimeError.new('Cannot build Atom feed: no articles')
      end
      if relevant_articles.any? { |a| a[:created_at].nil? }
        raise RuntimeError.new('Cannot build Atom feed: one or more articles lack created_at')
      end

      # Get sorted relevant articles
      sorted_relevant_articles = relevant_articles.sort_by { |a| Time.parse(a[:created_at]) }.reverse.first(limit)

      # Get most recent article
      last_article = sorted_relevant_articles.first

      # Create builder
      buffer = ''
      xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)

      # Build feed
      xml.instruct!
      xml.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
        root_url = @site.config[:base_url] + '/'

        # Add primary attributes
        xml.id      root_url
        xml.title   @item[:title]

        # Add date
        xml.updated Time.parse(last_article[:created_at]).to_iso8601_time

        # Add links
        xml.link(:rel => 'alternate', :href => root_url)
        xml.link(:rel => 'self',      :href => feed_url)

        # Add author information
        xml.author do
          xml.name  @item[:author_name]
          xml.uri   @item[:author_uri]
        end

        # Add articles
        sorted_relevant_articles.each do |a|
          # Get URL
          url = url_for(a)
          next if url.nil?

          xml.entry do
            # Add primary attributes
            xml.id        atom_tag_for(a)
            xml.title     a[:title], :type => 'html'

            # Add dates
            xml.published Time.parse(a[:created_at]).to_iso8601_time
            xml.updated   a.mtime.to_iso8601_time

            # Add link
            xml.link(:rel => 'alternate', :href => url)

            # Add content
            summary = excerpt_proc.call(a)
            xml.content   content_proc.call(a), :type => 'html'
            xml.summary   summary, :type => 'html' unless summary.nil?
          end
        end
      end

      buffer
    end

    # Returns the URL for the given item. It will return the URL containing
    # the custom path in the feed if possible, otherwise the normal path.
    def url_for(item)
      # Check attributes
      if @site.config[:base_url].nil?
        raise RuntimeError.new('Cannot build Atom feed: site configuration has no base_url')
      end

      # Get path
      path = item[:custom_path_in_feed] || item.reps[0].path
      return nil if path.nil?

      # Build URL
      @site.config[:base_url] + path
    end

    # Returns the URL of the feed. It will return the custom feed URL if set,
    # or otherwise the normal feed URL.
    def feed_url
      # Check attributes
      if @site.config[:base_url].nil?
        raise RuntimeError.new('Cannot build Atom feed: site configuration has no base_url')
      end

      @item[:feed_url] || @site.config[:base_url] + @item.reps[0].path
    end

    # Returns an URI containing an unique ID for the given item. This will be
    # used in the Atom feed to uniquely identify articles. These IDs are
    # created using a procedure suggested by Mark Pilgrim in this blog post:
    # http://diveintomark.org/archives/2004/05/28/howto-atom-id.
    def atom_tag_for(item)
      require 'time'

      hostname, base_dir = %r{^.+?://([^/]+)(.*)$}.match(@site.config[:base_url])[1..2]
      formatted_date     = Time.parse(item[:created_at]).to_iso8601_date

      'tag:' + hostname + ',' + formatted_date + ':' + base_dir + (item.reps[0].path || item.identifier)
    end

  end

end
