# encoding: utf-8

module Nanoc::Helpers

  # Provides functionality for building blogs, such as finding articles and
  # constructing feeds.
  #
  # This helper has a few requirements. First, all blog articles should have
  # the following attributes:
  #
  # * `kind` - Set to `"article"`
  #
  # * `created_at` - The article's publication timestamp
  #
  # Some functions in this blogging helper, such as the {#atom_feed} function,
  # require additional attributes to be set; these attributes are described in
  # the documentation for these functions.
  #
  # All "time" item attributes, site configuration attributes or method
  # parameters can either be a `Time` instance or a string in any format
  # parseable by `Time.parse`.
  #
  # The two main functions are {#sorted_articles} and {#atom_feed}.
  module Blogging

    # Returns an unsorted list of articles, i.e. items where the `kind`
    # attribute is set to `"article"`.
    #
    # @return [Array] An array containing all articles
    def articles
      @items.select { |item| item[:kind] == 'article' }
    end

    # Returns a sorted list of articles, i.e. items where the `kind`
    # attribute is set to `"article"`. Articles are sorted by descending
    # creation date, so newer articles appear before older articles.
    #
    # @return [Array] A sorted array containing all articles
    def sorted_articles
      articles.sort_by do |a|
        attribute_to_time(a[:created_at])
      end.reverse
    end

    class AtomFeedBuilder

      include Nanoc::Helpers::Blogging

      attr_accessor :site

      attr_accessor :limit
      attr_accessor :relevant_articles
      attr_accessor :content_proc
      attr_accessor :excerpt_proc
      attr_accessor :title
      attr_accessor :author_name
      attr_accessor :author_uri
      attr_accessor :icon
      attr_accessor :logo

      def initialize(site, item)
        @site = site
        @item = item
      end

      def validate
        self.validate_config
        self.validate_feed_item
        self.validate_articles
      end

      def build
        buffer = ''
        xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)
        self.build_for_feed(xml)
        buffer
      end

    protected

      def sorted_relevant_articles
        relevant_articles.sort_by do |a|
          attribute_to_time(a[:created_at])
        end.reverse.first(limit)
      end

      def last_article
        sorted_relevant_articles.first
      end

      def validate_config
        if @site.config[:base_url].nil?
          raise Nanoc::Errors::GenericTrivial.new('Cannot build Atom feed: site configuration has no base_url')
        end
      end

      def validate_feed_item
        if title.nil?
          raise Nanoc::Errors::GenericTrivial.new('Cannot build Atom feed: no title in params, item or site config')
        end
        if author_name.nil?
          raise Nanoc::Errors::GenericTrivial.new('Cannot build Atom feed: no author_name in params, item or site config')
        end
        if author_uri.nil?
          raise Nanoc::Errors::GenericTrivial.new('Cannot build Atom feed: no author_uri in params, item or site config')
        end
      end

      def validate_articles
        if relevant_articles.empty?
          raise Nanoc::Errors::GenericTrivial.new('Cannot build Atom feed: no articles')
        end
        if relevant_articles.any? { |a| a[:created_at].nil? }
          raise Nanoc::Errors::GenericTrivial.new('Cannot build Atom feed: one or more articles lack created_at')
        end
      end

      def build_for_feed(xml)
        xml.instruct!
        xml.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
          root_url = @site.config[:base_url] + '/'

          # Add primary attributes
          xml.id      root_url
          xml.title   title

          # Add date
          xml.updated(attribute_to_time(last_article[:created_at]).to_iso8601_time)

          # Add links
          xml.link(:rel => 'alternate', :href => root_url)
          xml.link(:rel => 'self',      :href => feed_url)

          # Add author information
          xml.author do
            xml.name  author_name
            xml.uri   author_uri
          end

          # Add icon and logo
          xml.icon icon if icon
          xml.logo logo if logo

          # Add articles
          sorted_relevant_articles.each do |a|
            self.build_for_article(a, xml)
          end
        end
      end

      def build_for_article(a, xml)
        # Get URL
        url = url_for(a)
        return if url.nil?

        xml.entry do
          # Add primary attributes
          xml.id        atom_tag_for(a)
          xml.title     a[:title], :type => 'html'

          # Add dates
          xml.published attribute_to_time(a[:created_at]).to_iso8601_time
          xml.updated   attribute_to_time(a[:updated_at] || a[:created_at]).to_iso8601_time

          # Add specific author information
          if a[:author_name] || a[:author_uri]
            xml.author do
              xml.name  a[:author_name] || author_name
              xml.uri   a[:author_uri]  || author_uri
            end
          end

          # Add link
          xml.link(:rel => 'alternate', :href => url)

          # Add content
          summary = excerpt_proc.call(a)
          xml.content   content_proc.call(a), :type => 'html'
          xml.summary   summary, :type => 'html' unless summary.nil?
        end
      end

    end

    # Returns a string representing the atom feed containing recent articles,
    # sorted by descending creation date.
    #
    # The following attributes must be set on blog articles:
    #
    # * `title` - The title of the blog post
    #
    # * `kind` and `created_at` (described above)
    #
    # The following attributes can optionally be set on blog articles to
    # change the behaviour of the Atom feed:
    #
    # * `excerpt` - An excerpt of the article, which is usually only a few
    #   lines long.
    #
    # * `custom_path_in_feed` - The path that will be used instead of the
    #   normal path in the feed. This can be useful when including
    #   non-outputted items in a feed; such items could have their custom feed
    #   path set to the blog path instead, for example.
    #
    # * `custom_url_in_feed` - The url that will be used instead of the
    #   normal url in the feed (generated from the site's base url + the item
    #   rep's path). This can be useful when building a link-blog where the
    #   URL of article is a remote location.
    #
    # * `updated_at` - The time when the article was last modified. If this
    #   attribute is not present, the `created_at` attribute will be used as
    #   the time when the article was last modified.
    #
    # The site configuration will need to have the following attributes:
    #
    # * `base_url` - The URL to the site, without trailing slash. For
    #   example, if the site is at "http://example.com/", the `base_url`
    #   would be "http://example.com".
    #
    # The feed item will need to know about the feed title, the feed author
    # name, and the URI corresponding to the author. These can be specified
    # using parameters, as attributes in the feed item, or in the site
    # configuration.
    #
    # * `title` - The title of the feed, which is usually also the title of
    #   the blog.
    #
    # * `author_name` - The name of the item's author.
    #
    # * `author_uri` - The URI for the item's author, such as the author's
    #   web site URL.
    #
    # The feed item can have the following optional attributes:
    #
    # * `feed_url` - The custom URL of the feed. This can be useful when the
    #   private feed URL shouldn't be exposed; for example, when using
    #   FeedBurner this would be set to the public FeedBurner URL.
    #
    # To construct a feed, create a new item and make sure that it is
    # filtered with `:erb` or `:erubis`; it should not be laid out. Ensure
    # that it is routed to the proper path, e.g. `/blog.xml`. It may also be
    # useful to set the `is_hidden` attribute to true, so that helpers such
    # as the sitemap helper will ignore the item. The content of the feed
    # item should be `<%= atom_feed %>`.
    #
    # @example Defining compilation and routing rules for a feed item
    #
    #   compile '/blog/feed/' do
    #     filter :erb
    #   end
    #
    #   route '/blog/feed/' do
    #     '/blog.xml'
    #   end
    #
    # @example Limiting the number of items in a feed
    #
    #   <%= atom_feed :limit => 5 %>
    #
    # @option params [Number] :limit (5) The maximum number of articles to
    #   show
    #
    # @option params [Array] :articles (sorted_articles) A list of articles to
    #   include in the feed
    #
    # @option params [Proc] :content_proc (->{ |article|
    #   article.compiled_content(:snapshot => :pre) }) A proc that returns the
    #   content of the given article, which is passed as a parameter. This
    #   function may not return nil.
    #
    # @option params [proc] :excerpt_proc (->{ |article| article[:excerpt] })
    #   A proc that returns the excerpt of the given article, passed as a
    #   parameter. This function should return nil if there is no excerpt.
    #
    # @option params [String] :title The feed's title, if it is not given in
    #   the item attributes.
    #
    # @option params [String] :author_name The name of the feed's author, if
    #   it is not given in the item attributes.
    #
    # @option params [String] :author_uri The URI of the feed's author, if it
    #   is not given in the item attributes.
    #
    # @option params [String] :icon The URI of the feed's icon.
    #
    # @option params [String] :logo The URI of the feed's logo.
    #
    # @return [String] The generated feed content
    def atom_feed(params={})
      require 'builder'

      # Create builder
      builder = AtomFeedBuilder.new(@site, @item)

      # Fill builder
      builder.limit             = params[:limit] || 5
      builder.relevant_articles = params[:articles] || articles || []
      builder.content_proc      = params[:content_proc] || lambda { |a| a.compiled_content(:snapshot => :pre) }
      builder.excerpt_proc      = params[:excerpt_proc] || lambda { |a| a[:excerpt] }
      builder.title             = params[:title] || @item[:title] || @site.config[:title]
      builder.author_name       = params[:author_name] || @item[:author_name] || @site.config[:author_name]
      builder.author_uri        = params[:author_uri] || @item[:author_uri] || @site.config[:author_uri]
      builder.icon              = params[:icon]
      builder.logo              = params[:logo]

      # Run
      builder.validate
      builder.build
    end

    # Returns the URL for the given item. It will return the URL containing
    # the custom path in the feed if possible, otherwise the normal path.
    #
    # @param [Nanoc::Item] item The item for which to fetch the URL.
    #
    # @return [String] The URL of the given item
    def url_for(item)
      # Check attributes
      if @site.config[:base_url].nil?
        raise Nanoc::Errors::GenericTrivial.new('Cannot build Atom feed: site configuration has no base_url')
      end

      # Build URL
      if item[:custom_url_in_feed]
        item[:custom_url_in_feed]
      elsif item[:custom_path_in_feed]
        @site.config[:base_url] + item[:custom_path_in_feed]
      elsif item.path
        @site.config[:base_url] + item.path
      end
    end

    # Returns the URL of the feed. It will return the custom feed URL if set,
    # or otherwise the normal feed URL.
    #
    # @return [String] The URL of the feed
    def feed_url
      # Check attributes
      if @site.config[:base_url].nil?
        raise Nanoc::Errors::GenericTrivial.new('Cannot build Atom feed: site configuration has no base_url')
      end

      @item[:feed_url] || @site.config[:base_url] + @item.path
    end

    # Returns an URI containing an unique ID for the given item. This will be
    # used in the Atom feed to uniquely identify articles. These IDs are
    # created using a procedure suggested by Mark Pilgrim and described in his
    # ["How to make a good ID in Atom" blog post]
    # (http://diveintomark.org/archives/2004/05/28/howto-atom-id).
    #
    # @param [Nanoc::Item] item The item for which to create an atom tag
    #
    # @return [String] The atom tag for the given item
    def atom_tag_for(item)
      hostname, base_dir = %r{^.+?://([^/]+)(.*)$}.match(@site.config[:base_url])[1..2]

      formatted_date = attribute_to_time(item[:created_at]).to_iso8601_date

      'tag:' + hostname + ',' + formatted_date + ':' + base_dir + (item.path || item.identifier)
    end

    # Converts the given attribute (which can be a string, a Time or a Date)
    # into a Time.
    #
    # @param [String, Time, Date] time Something that contains time
    #   information but is not necessarily a Time instance yet
    #
    # @return [Time] The Time instance corresponding to the given input
    def attribute_to_time(time)
      time = Time.local(time.year, time.month, time.day) if time.is_a?(Date)
      time = Time.parse(time) if time.is_a?(String)
      time
    end

  end

end
