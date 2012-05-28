# encoding: utf-8

module Nanoc::Extra::Checking::Checkers

  # A checker that verifies that all internal links point to a location that exists.
  class InternalLinks < ::Nanoc::Extra::Checking::Checker

    # Starts the validator. The results will be printed to stdout.
    #
    # @return [void]
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
        hrefs.reject { |href| is_external_href?(href) }.each do |href|
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
      return true if File.directory?(path) && @site.config[:index_filenames].any? { |fn| File.file?(File.join(path, fn)) }

      # Nope :(
      return false
    end

    def validate_hrefs(hrefs)
      broken_hrefs = {}
      hrefs.each_pair do |href, filenames|
        filenames.each do |filename|
          if !is_valid_internal_href?(href, filename)
            broken_hrefs[href] = filenames
          end
        end
      end
      broken_hrefs
    end

  end

end

