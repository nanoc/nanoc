# encoding: utf-8

module ::Nanoc::Extra::Checking::Checkers

  # A validator that verifies that all external links point to a location that exists.
  class ExternalLinks < ::Nanoc::Extra::Checking::Checker

    identifiers :external_links, :elinks

    def run
      require 'nokogiri'

      all_broken_hrefs.each_pair do |href, filenames|
        filenames.each do |filename|
          self.issues << "Broken link: #{href} (referenced from #{filename})"
        end
      end
    end

  private

    # Enumerates all key-value pairs of a given hash in a thread-safe way.
    #
    # @api private
    class ThreadsafeHashEnumerator

      # Creates a new enumerator for the given hash.
      #
      # @param [Hash] hash The hash for which the enumerator should return
      #   key-value pairs
      def initialize(hash)
        @hash             = hash
        @unprocessed_keys = @hash.keys.dup
        @mutex            = Mutex.new
      end

      # Returns the next key-value pair in the hash.
      #
      # @return [Array] An array containing the key and the corresponding
      #   value of teh next key-value pair
      def next_pair
        @mutex.synchronize do
          key = @unprocessed_keys.shift
          return (key ? [ key, @hash[key] ] : nil)
        end
      end

    end

    def all_broken_hrefs
      broken_hrefs  = {}
      grouped_hrefs = {}

      all_hrefs_per_filename.each_pair do |filename, hrefs|
        hrefs.select { |href| is_external_href?(href) }.each do |href|
          grouped_hrefs[href] ||= []
          grouped_hrefs[href] << filename
        end
      end

      validate_hrefs(grouped_hrefs)
    end

    def all_files
      Dir[@site.config[:output_dir] + '/**/*.html']
    end

    def all_hrefs_per_filename
      hrefs = {}
      all_files.each do |filename|
        hrefs[filename] ||= all_hrefs_in_file(filename)
      end
      hrefs
    end

    def all_hrefs_in_file(filename)
      doc = Nokogiri::HTML(::File.read(filename))
      doc.css('a').map { |l| l[:href] }.compact
    end

    def is_external_href?(href)
      !!(href =~ %r{^[a-z\-]+:})
    end

    def is_valid_external_href?(href)
      require 'net/http'
      require 'uri'

      # Parse
      uri = nil
      begin
        uri = URI.parse(href)
      rescue URI::InvalidURIError
        @delegate && @delegate.send(:external_href_validated, href, false)
        return false
      end

      # Skip non-HTTP URLs
      return true if uri.scheme !~ /^https?$/

      # Get status
      status = fetch_http_status_for(uri)
      is_valid = !status.nil? && status == 200

      # Done
      is_valid
    end

    def validate_hrefs(hrefs)
      broken_hrefs = {}
      @mutex = Mutex.new
      enum = ThreadsafeHashEnumerator.new(hrefs)

      threads = []
      10.times do
        threads << Thread.new do
          loop do
            # Get next pair
            pair = enum.next_pair
            break if pair.nil?
            href, filenames = pair[0], pair[1]

            # Validate
            if !is_valid_external_href?(href)
              @mutex.synchronize do
                broken_hrefs[href] = filenames
              end
            end
          end
        end
      end
      threads.each { |t| t.join }
      broken_hrefs
    end

    def fetch_http_status_for(url, params={})
      5.times do |i|
        begin
          res = nil
          Timeout::timeout(10) do
            res = request_url_once(url)
          end

          if res.code =~ /^3..$/
            return nil if i == 5

            # Find proper location
            location = res['Location']
            if location !~ /^https?:\/\//
              base_url = url.dup
              base_url.path = (location =~ /^\// ? '' : '/')
              base_url.query = nil
              base_url.fragment = nil
              location = base_url.to_s + location
            end

            url = URI.parse(location)
          else
            return res.code.to_i
          end
        rescue
          return nil
        end
      end
    end

    def request_url_once(url)
      require 'net/https'

      path = (url.path.nil? || url.path.empty? ? '/' : url.path)
      req = Net::HTTP::Head.new(path)
      http = Net::HTTP.new(url.host, url.port)
      if url.instance_of? URI::HTTPS
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      res = http.request(req)
    end

  end

end

