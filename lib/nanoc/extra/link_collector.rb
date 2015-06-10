require 'set'

module ::Nanoc::Extra
  # @api private
  class LinkCollector
    URI_ATTRS = {
      'a' => :href,
      'audio' => :src,
      'form' => :action,
      'iframe' => :src,
      'img' => :src,
      'link' => :href,
      'script' => :src,
      'video' => :src,
    }

    def initialize(filenames, mode = nil)
      Nanoc::Extra::JRubyNokogiriWarner.check_and_warn

      @filenames = filenames
      @filter =
        case mode
        when nil
          ->(_h) { true }
        when :external
          ->(h) { external_href?(h) }
        when :internal
          ->(h) { !external_href?(h) }
        else
          raise ArgumentError, 'Expected mode argument to be :internal, :external or nil'
        end
    end

    def filenames_per_href
      require 'nokogiri'
      filenames_per_href = {}
      @filenames.each do |filename|
        hrefs_in_file(filename).each do |href|
          filenames_per_href[href] ||= Set.new
          filenames_per_href[href] << filename
        end
      end
      filenames_per_href
    end

    def filenames_per_resource_uri
      require 'nokogiri'
      filenames_per_resource_uri = {}
      @filenames.each do |filename|
        resource_uris_in_file(filename).each do |resouce_uri|
          filenames_per_resource_uri[resouce_uri] ||= Set.new
          filenames_per_resource_uri[resouce_uri] << filename
        end
      end
      filenames_per_resource_uri
    end

    def external_href?(href)
      href =~ %r{^(\/\/|[a-z\-]+:)}
    end

    def hrefs_in_file(filename)
      uris_in_file filename, %w(a img)
    end

    def resource_uris_in_file(filename)
      uris_in_file filename, %w(audio form img iframe link script video)
    end

    private

    def uris_in_file(filename, tag_names)
      uris = Set.new
      doc = Nokogiri::HTML(::File.read(filename))
      tag_names.each do |tag_name|
        attr = URI_ATTRS[tag_name]
        doc.css(tag_name).each do |e|
          uris << e[attr] unless e[attr].nil?
        end
      end

      # Strip fragment
      uris.map! { |href| href.gsub(/#.*$/, '') }

      uris.select(&@filter)
    end
  end
end
