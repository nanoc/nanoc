# encoding: utf-8

module Nanoc::Extra::Checking::Checkers

  # A checker that verifies that all internal links point to a location that exists.
  class InternalLinks < ::Nanoc::Extra::Checking::Checker

    # Starts the validator. The results will be printed to stdout.
    #
    # @return [void]
    def run
      require 'nokogiri'

      hrefs_with_filenames = ::Nanoc::Extra::LinkCollector.new(self.output_filenames, :internal).filenames_per_href
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

      # Remove target
      path = href.sub(/#.*$/, '')
      return true if path.empty?

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

  end

end

