# encoding: utf-8

module ::Nanoc::Extra::Checking::Checkers

  # A validator that verifies that all external links point to a location that exists.
  class ExternalLinks < ::Nanoc::Extra::Checking::Checker

    identifiers :external_links, :elinks

    def run
      require 'net/http'
      require 'net/https'
      require 'nokogiri'
      require 'uri'

      # Find all broken external hrefs
      hrefs_with_filenames = ::Nanoc::Extra::LinkCollector.new(self.output_filenames, :external).filenames_per_href
      results = self.select_invalid(hrefs_with_filenames.keys)

      # Report them
      results.each do |res|
        filenames = hrefs_with_filenames[res.href]
        filenames.each do |filename|
          self.add_issue(
            "Broken reference to #{res.href} (#{res.explanation})",
            :subject => filename,
            :severity => res.severity)
        end
      end
    end

    class Result

      attr_reader :href
      attr_reader :explanation
      attr_reader :severity

      def initialize(href, explanation, severity)
        @href = href
        @explanation = explanation
        @severity = severity
      end

    end

    class ArrayEnumerator

      def initialize(array)
        @array = array
        @index = 0
        @mutex = Mutex.new
      end

      def next
        @mutex.synchronize do
          @index += 1
          return @array[@index-1]
        end
      end

    end

    def select_invalid(hrefs)
      enum = ArrayEnumerator.new(hrefs.sort)
      mutex = Mutex.new
      invalid = Set.new

      threads = []
      10.times do
        threads << Thread.new do
          loop do
            href = enum.next
            break if href.nil?
            res = self.validate(href)
            unless res.nil?
              mutex.synchronize do
                invalid << res
              end
            end
          end
        end
      end
      threads.each { |t| t.join }

      invalid
    end

    def validate(href)
      # Parse
      uri = nil
      begin
        uri = URI.parse(href)
      rescue URI::InvalidURIError
        return Result.new(href, 'invalid URI', :error)
      end

      # Skip non-HTTP URLs
      return Result.new(href, 'can only check http/https', :skipped) if uri.scheme !~ /^https?$/

      # Get status
      failure, severity = failure_for(uri)
      if severity == :ok
        Result.new(href, 'ok', :ok)
      else
        Result.new(href, failure, severity)
      end
    end

    def failure_for(url, params={})
      res = nil
      5.times do |i|
        begin
          Timeout::timeout(10) do
            res = request_url_once(url)
          end
        rescue => e
          return e.message, :error
        end

        if res.code =~ /^3..$/
          return 'too many redirects', :warning if i == 4

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
        elsif res.code == '200'
          return nil, :ok
        else
          return res.code, :error
        end
      end
      return '???', :error
    end

    def request_url_once(url)
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
