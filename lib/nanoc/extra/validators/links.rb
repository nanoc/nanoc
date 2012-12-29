# encoding: utf-8

module Nanoc::Extra::Validators

  # A validator that verifies that all links (`<a href="…">…</a>`) point to a
  # location that exists.
  class Links

    # @param [String] dir The directory that will be searched for HTML files
    #   to validate
    #
    # @param [Array<String>] index_filenames An array of index filenames that
    #   will be appended to URLs by web servers if a directory is requested
    #   instead of a file
    #
    # @option params [Boolean] :internal (false) True if internal links should
    #   be checked; false if they should not
    #
    # @option params [Boolean] :external (false) True if external links should
    #   be checked; false if they should not
    def initialize(dir, index_filenames, params={})
      @dir              = dir
      @index_filenames  = index_filenames
      @include_internal = params.has_key?(:internal) && params[:internal]
      @include_external = params.has_key?(:external) && params[:external]
    end

    # Starts the validator. The results will be printed to stdout.
    #
    # @return [void]
    def run
      require 'nokogiri'

      @delegate = self
      links = all_broken_hrefs
      if links.empty?
        puts "No broken links found!"
      else
        links.each_pair do |href, origins|
          puts "Broken link: #{href} -- referenced from:"
          origins.each do |origin|
            puts "    #{origin}"
          end
          puts
        end
      end
    end

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

  private

    def all_broken_hrefs
      broken_hrefs = {}

      internal_hrefs = {}
      external_hrefs = {}

      # Split into internal and external hrefs
      all_hrefs_per_filename.each_pair do |filename, hrefs|
        hrefs.each do |href|
          if is_external_href?(href)
            external_hrefs[href] ||= []
            external_hrefs[href] << filename
          else
            internal_hrefs[href] ||= []
            internal_hrefs[href] << filename
          end
        end
      end

      # Validate hrefs
      validate_internal_hrefs(internal_hrefs, broken_hrefs) if @include_internal
      validate_external_hrefs(external_hrefs, broken_hrefs) if @include_external

      # Done
      broken_hrefs
    end

    def all_files
      Dir[@dir + '/**/*.html']
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

    def is_valid_internal_href?(href, origin)
      # Skip hrefs that point to self
      # FIXME this is ugly and won’t always be correct
      return true if href == '.'

      # Remove target
      path = href.sub(/#.*$/, '')
      return true if path.empty?

      # Make absolute
      if path[0, 1] == '/'
        path = @dir + path
      else
        path = ::File.expand_path(path, ::File.dirname(origin))
      end

      # Check whether file exists
      return true if File.file?(path)

      # Check whether directory with index file exists
      return true if File.directory?(path) && @index_filenames.any? { |fn| File.file?(File.join(path, fn)) }

      # Nope :(
      return false
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

      # Notify
      @delegate && @delegate.send(:external_href_validated, href, is_valid)

      # Done
      is_valid
    end

    def validate_internal_hrefs(hrefs, broken_hrefs)
      hrefs.each_pair do |href, filenames|
        filenames.each do |filename|
          if !is_valid_internal_href?(href, filename)
            broken_hrefs[href] = filenames
          end
        end
      end
    end

    def validate_external_hrefs(hrefs, broken_hrefs)
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

    def external_href_validated(href, is_valid)
      texts = {
        true  => 'ok',
        false => ' ERROR '
      }

      colors = {
        true     => "\e[32m",
        false    => "\e[41m\e[37m",
        :off     => "\033[0m"
      }

      @mutex.synchronize do
        puts href + ': ' + colors[is_valid] + texts[is_valid] + colors[:off]
      end
    end

  end

end
