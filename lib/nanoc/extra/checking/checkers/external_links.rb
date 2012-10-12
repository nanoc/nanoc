# encoding: utf-8

require 'net/http'
require 'net/https'
require 'nokogiri'
require 'timeout'
require 'uri'

module ::Nanoc::Extra::Checking::Checkers

  # A validator that verifies that all external links point to a location that exists.
  class ExternalLinks < ::Nanoc::Extra::Checking::Checker

    identifiers :external_links, :elinks

    def run
      # Find all broken external hrefs
      hrefs_with_filenames = ::Nanoc::Extra::LinkCollector.new(self.output_filenames, :external).filenames_per_href
      results = self.select_invalid(hrefs_with_filenames.keys)

      # Report them
      results.each do |res|
        filenames = hrefs_with_filenames[res.href]
        filenames.each do |filename|
          self.add_issue(
            "reference to #{res.href}: #{res.explanation}",
            :subject => filename)
        end
      end
    end

    class Result

      attr_reader :href
      attr_reader :explanation

      def initialize(href, explanation)
        @href        = href
        @explanation = explanation
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
            if res
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
      url = nil
      begin
        url = URI.parse(href)
      rescue URI::InvalidURIError
        return Result.new(href, 'invalid URI')
      end

      # Skip non-HTTP URLs
      return nil if url.scheme !~ /^https?$/

      # Get status
      res = nil
      5.times do |i|
        begin
          Timeout::timeout(10) do
            res = request_url_once(url)
          end
        rescue => e
          return Result.new(href, e.message)
        end

        if res.code =~ /^3..$/
          if i == 4
            return Result.new(href, 'too many redirects')
          end

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
          return nil
        else
          return Result.new(href, res.code)
        end
      end
      raise 'should not have gotten here'
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
