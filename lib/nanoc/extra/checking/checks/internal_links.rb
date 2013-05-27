# encoding: utf-8

require 'uri'

module Nanoc::Extra::Checking::Checks

  # A check that verifies that all internal links point to a location that exists.
  class InternalLinks < ::Nanoc::Extra::Checking::Check

    identifiers :internal_links, :ilinks

    # Starts the validator. The results will be printed to stdout.
    #
    # Internal links that match a regexp pattern in `@config[:checks][:internal_links][:exclude]` will
    # be skipped.
    #
    # @return [void]
    def run
      # TODO de-duplicate this (duplicated in external links check)
      filenames = self.output_filenames.select { |f| File.extname(f) == '.html' }
      hrefs_with_filenames = ::Nanoc::Extra::LinkCollector.new(filenames, :internal).filenames_per_href
      hrefs_with_filenames.each_pair do |href, filenames|
        filenames.each do |filename|
          unless valid?(href, filename)
          self.add_issue(
            "reference to #{href}",
            :subject  => filename)
          end
        end
      end
    end

  protected

    def valid?(href, origin)
      # Skip hrefs that point to self
      # FIXME this is ugly and won’t always be correct
      return true if href == '.'

      # Skip hrefs that are specified in the exclude configuration
      return true if self.excluded?(href)

      # Remove target
      path = href.sub(/#.*$/, '')
      return true if path.empty?

      # Remove query string
      path = path.sub(/\?.*$/, '')
      return true if path.empty?

      # Decode URL (e.g. '%20' -> ' ')
      path = URI.unescape(path)

      # Make absolute
      if path[0, 1] == '/'
        path = @site.config[:output_dir] + path
      else
        path = ::File.expand_path(path, ::File.dirname(origin))
      end

      # Check whether file exists
      return true if File.file?(path)

      # Check whether directory with index file exists
      return true if File.directory?(path) && @site.config[:index_filenames].any? { |fn| File.file?(File.join(path, fn)) }

      # Nope :(
      return false
    end

    def excluded?(href)
      excludes =  @site.config.fetch(:checks, {}).fetch(:internal_links, {}).fetch(:exclude, [])
      excludes.any? { |pattern| Regexp.new(pattern).match(href) }
    end

  end

end

