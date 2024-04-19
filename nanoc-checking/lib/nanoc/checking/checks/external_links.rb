# frozen_string_literal: true

module Nanoc
  module Checking
    module Checks
      # A validator that verifies that all external links point to a location that exists.
      #
      # @api private
      class ExternalLinks < ::Nanoc::Checking::Check
        identifiers :external_links, :elinks

        def run
          # Find all broken external hrefs
          # TODO: de-duplicate this (duplicated in internal links check)
          filenames = output_html_filenames.reject { |f| excluded_file?(f) }
          hrefs_with_filenames = ::Nanoc::Checking::LinkCollector.new(filenames, :external).filenames_per_href
          results = select_invalid(hrefs_with_filenames.keys.shuffle)

          # Report them
          results.each do |res|
            filenames = hrefs_with_filenames[res.href]
            filenames.each do |filename|
              add_issue(
                "broken reference to <#{res.href}>: #{res.explanation}",
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
          ::Parallel.map(hrefs, in_threads: 10) { |href| validate(href) }.compact
        end

        def validate(href)
          # Skip javascript: URLs
          #
          # This needs to be handled explicitly, because URI.parse does not
          # like `javascript:` URLs -- presumably because those are not
          # technically valid URLs.
          return nil if href.start_with?('javascript:')

          # Parse
          url = nil
          begin
            url = URI.parse(href)
          rescue URI::Error
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

            case res.code
            when /^3..$/
              if i == 4
                return Result.new(href, 'too many redirects')
              end

              location = extract_location(res, url)
              return Result.new(href, 'redirection without a target location') if location.nil?

              # ignore redirects back onto self (misused to set HTTP cookies)
              return nil if href == location

              if /^30[18]$/.match?(res.code)
                return Result.new(href, "link has moved permanently to '#{location}'")
              end

              url = URI.parse(location)
            when '200'
              return nil
            else
              return Result.new(href, res.code)
            end
          end

          if last_err
            Result.new(href, last_err.message)
          else
            raise Nanoc::Core::Errors::InternalInconsistency, 'last_err cannot be nil'
          end
        end

        def extract_location(res, url)
          location = res['Location']

          case location
          when nil
            nil
          when /^https?:\/\//
            location
          else
            base_url = url.dup
            base_url.path = (/^\//.match?(location) ? '' : '/')
            base_url.query = nil
            base_url.fragment = nil
            base_url.to_s + location
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
          req['User-Agent'] = "Mozilla/5.0 Nanoc/#{Nanoc::VERSION} (link rot checker)"
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
  end
end
