# encoding: utf-8

require 'set'

module ::Nanoc::Extra

  class LinkCollector

    def initialize(filenames, mode=nil)
      @filenames = filenames
      @filter = case mode
        when nil
          lambda { |h| true }
        when :external
          lambda { |h| external_href?(h) }
        when :internal
          lambda { |h| !external_href?(h) }
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

    def external_href?(href)
      !!(href =~ %r{^(\/\/|[a-z\-]+:)})
    end

    def hrefs_in_file(filename)
      hrefs_in_file = Set.new
      doc = Nokogiri::HTML(::File.read(filename))
      doc.css('a').each   { |e| hrefs_in_file << e[:href] }
      doc.css('img').each { |e| hrefs_in_file << e[:src]  }

      # Convert protocol-relative urls
      # e.g. //example.com => http://example.com
      hrefs_in_file.map! { |href| href.gsub /^\/\//, 'http://' }
      
      hrefs_in_file.select(&@filter)
    end

  end

end
