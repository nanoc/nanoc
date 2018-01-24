# frozen_string_literal: true

module Nanoc::Helpers
  # @see http://nanoc.ws/doc/reference/helpers/#blogging
  module Blogging
    # @return [Array]
    def articles
      blk = -> { @items.select { |item| item[:kind] == 'article' } }
      if @items.frozen?
        @article_items ||= blk.call
      else
        blk.call
      end
    end

    # @return [Array]
    def sorted_articles
      blk = -> { articles.sort_by { |a| attribute_to_time(a[:created_at]) }.reverse }

      if @items.frozen?
        @sorted_article_items ||= blk.call
      else
        blk.call
      end
    end

    class AtomFeedBuilder
      include Nanoc::Helpers::Blogging

      attr_accessor :config

      attr_accessor :alt_link
      attr_accessor :id
      attr_accessor :limit
      attr_accessor :relevant_articles
      attr_accessor :preserve_order
      attr_accessor :content_proc
      attr_accessor :excerpt_proc
      attr_accessor :title
      attr_accessor :author_name
      attr_accessor :author_uri
      attr_accessor :icon
      attr_accessor :logo

      def initialize(config, item)
        @config = config
        @item = item
      end

      def validate
        validate_config
        validate_feed_item
        validate_articles
      end

      def build
        buffer = +''
        xml = Builder::XmlMarkup.new(target: buffer, indent: 2)
        build_for_feed(xml)
        buffer
      end

      protected

      def sorted_relevant_articles
        all = relevant_articles

        unless @preserve_order
          all = all.sort_by { |a| attribute_to_time(a[:created_at]) }
        end

        all.reverse.first(limit)
      end

      def last_article
        sorted_relevant_articles.first
      end

      def updated
        relevant_articles.map { |a| attribute_to_time(a[:updated_at] || a[:created_at]) }.max
      end

      def validate_config
        if @config[:base_url].nil?
          raise Nanoc::Int::Errors::GenericTrivial.new('Cannot build Atom feed: site configuration has no base_url')
        end
      end

      def validate_feed_item
        if title.nil?
          raise Nanoc::Int::Errors::GenericTrivial.new('Cannot build Atom feed: no title in params, item or site config')
        end
        if author_name.nil?
          raise Nanoc::Int::Errors::GenericTrivial.new('Cannot build Atom feed: no author_name in params, item or site config')
        end
        if author_uri.nil?
          raise Nanoc::Int::Errors::GenericTrivial.new('Cannot build Atom feed: no author_uri in params, item or site config')
        end
      end

      def validate_articles
        if relevant_articles.empty?
          raise Nanoc::Int::Errors::GenericTrivial.new('Cannot build Atom feed: no articles')
        end
        if relevant_articles.any? { |a| a[:created_at].nil? }
          raise Nanoc::Int::Errors::GenericTrivial.new('Cannot build Atom feed: one or more articles lack created_at')
        end
      end

      def build_for_feed(xml)
        root_url = @config[:base_url] + '/'
        xml.instruct!
        xml.feed(xmlns: 'http://www.w3.org/2005/Atom', 'xml:base' => root_url) do
          # Add primary attributes
          xml.id(id || root_url)
          xml.title title

          # Add date
          xml.updated(updated.__nanoc_to_iso8601_time)

          # Add links
          xml.link(rel: 'alternate', href: (alt_link || root_url))
          xml.link(rel: 'self',      href: feed_url)

          # Add author information
          xml.author do
            xml.name author_name
            xml.uri author_uri
          end

          # Add icon and logo
          xml.icon icon if icon
          xml.logo logo if logo

          # Add articles
          sorted_relevant_articles.each do |a|
            build_for_article(a, xml)
          end
        end
      end

      def build_for_article(article, xml)
        # Get URL
        url = url_for(article)
        return if url.nil?

        xml.entry do
          # Add primary attributes
          xml.id atom_tag_for(article)
          xml.title article[:title], type: 'html'

          # Add dates
          xml.published attribute_to_time(article[:created_at]).__nanoc_to_iso8601_time
          xml.updated attribute_to_time(article[:updated_at] || article[:created_at]).__nanoc_to_iso8601_time

          # Add specific author information
          if article[:author_name] || article[:author_uri]
            xml.author do
              xml.name article[:author_name] || author_name
              xml.uri article[:author_uri] || author_uri
            end
          end

          # Add link
          xml.link(rel: 'alternate', href: url)

          # Add content
          summary = excerpt_proc.call(article)
          xml.content content_proc.call(article), type: 'html'
          xml.summary summary, type: 'html' unless summary.nil?
        end
      end
    end

    # @option params [Number] :limit
    # @option params [Array] :articles
    # @option params [Boolean] :preserve_order
    # @option params [Proc] :content_proc
    # @option params [Proc] :excerpt_proc
    # @option params [String] :alt_link
    # @option params [String] :id
    # @option params [String] :title
    # @option params [String] :author_name
    # @option params [String] :author_uri
    # @option params [String] :icon
    # @option params [String] :logo
    #
    # @return [String]
    def atom_feed(params = {})
      require 'builder'

      # Create builder
      builder = AtomFeedBuilder.new(@config, @item)

      # Fill builder
      builder.alt_link          = params[:alt_link]
      builder.id                = params[:id]
      builder.limit             = params[:limit] || 5
      builder.relevant_articles = params[:articles] || articles || []
      builder.preserve_order    = params.fetch(:preserve_order, false)
      builder.content_proc      = params[:content_proc] || ->(a) { a.compiled_content(snapshot: :pre) }
      builder.excerpt_proc      = params[:excerpt_proc] || ->(a) { a[:excerpt] }
      builder.title             = params[:title] || @item[:title] || @config[:title]
      builder.author_name       = params[:author_name] || @item[:author_name] || @config[:author_name]
      builder.author_uri        = params[:author_uri] || @item[:author_uri] || @config[:author_uri]
      builder.icon              = params[:icon]
      builder.logo              = params[:logo]

      # Run
      builder.validate
      builder.build
    end

    # @return [String]
    def url_for(item)
      # Check attributes
      if @config[:base_url].nil?
        raise Nanoc::Int::Errors::GenericTrivial.new('Cannot build Atom feed: site configuration has no base_url')
      end

      # Build URL
      if item[:custom_url_in_feed]
        item[:custom_url_in_feed]
      elsif item[:custom_path_in_feed]
        @config[:base_url] + item[:custom_path_in_feed]
      elsif item.path
        @config[:base_url] + item.path
      end
    end

    # @return [String]
    def feed_url
      # Check attributes
      if @config[:base_url].nil?
        raise Nanoc::Int::Errors::GenericTrivial.new('Cannot build Atom feed: site configuration has no base_url')
      end

      @item[:feed_url] || @config[:base_url] + @item.path
    end

    # @return [String]
    def atom_tag_for(item)
      hostname, base_dir = %r{^.+?://([^/]+)(.*)$}.match(@config[:base_url])[1..2]

      formatted_date = attribute_to_time(item[:created_at]).__nanoc_to_iso8601_date

      'tag:' + hostname + ',' + formatted_date + ':' + base_dir + (item.path || item.identifier.to_s)
    end

    # @param [String, Time, Date, DateTime] arg
    #
    # @return [Time]
    def attribute_to_time(arg)
      case arg
      when DateTime
        arg.to_time
      when Date
        Time.utc(arg.year, arg.month, arg.day)
      when String
        Time.parse(arg)
      else
        arg
      end
    end
  end
end
