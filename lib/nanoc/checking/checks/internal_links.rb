# frozen_string_literal: true

require 'uri'

module Nanoc::Checking::Checks
  # A check that verifies that all internal links point to a location that exists.
  #
  # @api private
  class InternalLinks < ::Nanoc::Checking::Check
    identifiers :internal_links, :ilinks

    # Starts the validator. The results will be printed to stdout.
    #
    # Internal links that match a regexp pattern in `@config[:checks][:internal_links][:exclude]` will
    # be skipped.
    #
    # @return [void]
    def run
      # TODO: de-duplicate this (duplicated in external links check)
      filenames = output_filenames.select { |f| File.extname(f) == '.html' }
      hrefs_with_filenames = ::Nanoc::Extra::LinkCollector.new(filenames, :internal).filenames_per_href
      resource_uris_with_filenames = ::Nanoc::Extra::LinkCollector.new(filenames, :internal).filenames_per_resource_uri

      uris = hrefs_with_filenames.merge(resource_uris_with_filenames)
      uris.each_pair do |href, fns|
        fns.each do |filename|
          next if valid?(href, filename)

          add_issue(
            "broken reference to #{href}",
            subject: filename,
          )
        end
      end
    end

    protected

    def valid?(href, origin)
      # Skip hrefs that point to self
      # FIXME: this is ugly and won’t always be correct
      return true if href == '.'

      # Skip hrefs that are specified in the exclude configuration
      return true if excluded?(href, origin)

      # Remove target
      path = href.sub(/#.*$/, '')
      return true if path.empty?

      # Remove query string
      path = path.sub(/\?.*$/, '')
      return true if path.empty?

      # Decode URL (e.g. '%20' -> ' ')
      path = URI.unescape(path)

      # Make absolute
      path =
        if path[0, 1] == '/'
          @config[:output_dir] + path
        else
          ::File.expand_path(path, ::File.dirname(origin))
        end

      # Check whether file exists
      return true if File.file?(path)

      # Check whether directory with index file exists
      return true if File.directory?(path) && @config[:index_filenames].any? { |fn| File.file?(File.join(path, fn)) }

      # Nope :(
      false
    end

    def excluded?(href, origin)
      config = @config.fetch(:checks, {}).fetch(:internal_links, {})
      excluded_target?(href, config) || excluded_origin?(origin, config)
    end

    def excluded_target?(href, config)
      excludes = config.fetch(:exclude_targets, config.fetch(:exclude, []))
      excludes.any? { |pattern| Regexp.new(pattern).match(href) }
    end

    def excluded_origin?(origin, config)
      relative_origin = origin[@config[:output_dir].size..-1]
      excludes = config.fetch(:exclude_origins, [])
      excludes.any? { |pattern| Regexp.new(pattern).match(relative_origin) }
    end
  end
end
