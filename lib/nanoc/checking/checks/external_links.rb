# frozen_string_literal: true

require 'net/http'
require 'net/https'
require 'timeout'
require 'uri'

module ::Nanoc::Checking::Checks
  # A validator that verifies that all external links point to a location that exists.
  #
  # @api private
  class ExternalLinks < ::Nanoc::Checking::Check
    identifiers :external_links, :elinks

    def run
      # Find all broken external hrefs
      # TODO: de-duplicate this (duplicated in internal links check)
      filenames = output_filenames.select { |f| File.extname(f) == '.html' && !excluded_file?(f) }
      hrefs_with_filenames = ::Nanoc::Extra::LinkCollector.new(filenames, :external).filenames_per_href
      results = select_invalid(hrefs_with_filenames.keys)

      # Report them
      results.each do |res|
        filenames = hrefs_with_filenames[res.href]
        filenames.each do |filename|
          add_issue(
            "broken reference to #{res.href}: #{res.explanation}",
            subject: filename,
          )
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

    def select_invalid(hrefs)
      col = Nanoc::Extra::ParallelCollection.new(hrefs, parallelism: 10)
      col.map { |href| validate(href) }.compact
    end

    def validate(href)
      # Parse
      url = nil
      begin
        url = URI.parse(href)
      rescue URI::InvalidURIError
        return Result.new(href, 'invalid URI')
      end

      # Skip excluded URLs
      return nil if excluded?(href)

      # Skip non-HTTP URLs
      return nil if url.scheme !~ /^https?$/

      # Get status
      res = nil
      last_err = nil
      timeouts = [3, 5, 10, 30, 60]
      5.times do |i|
        begin
          Timeout.timeout(timeouts[i]) do
            res = request_url_once(url)
          end
        rescue => e
          last_err = e
          next
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
      if last_err
        return Result.new(href, last_err.message)
      else
        raise Nanoc::Int::Errors::InternalInconsistency, 'last_err cannot be nil'
      end
    end

    def path_for_url(url)
      path =
        if url.path.nil? || url.path.empty?
          '/'
        else
          url.path
        end

      if url.query
        path = path + '?' + url.query
      end

      path
    end

    def request_url_once(url)
      req = Net::HTTP::Get.new(path_for_url(url))
      http = Net::HTTP.new(url.host, url.port)
      if url.instance_of? URI::HTTPS
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http.request(req)
    end

    def excluded?(href)
      excludes = @config.fetch(:checks, {}).fetch(:external_links, {}).fetch(:exclude, [])
      excludes.any? { |pattern| Regexp.new(pattern).match(href) }
    end

    def excluded_file?(file)
      excludes = @config.fetch(:checks, {}).fetch(:external_links, {}).fetch(:exclude_files, [])
      excludes.any? { |pattern| Regexp.new(pattern).match(file) }
    end
  end
end
