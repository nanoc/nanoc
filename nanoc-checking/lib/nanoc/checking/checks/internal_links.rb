# frozen_string_literal: true

module Nanoc
  module Checking
    module Checks
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
          filenames = output_html_filenames
          uris = ::Nanoc::Checking::LinkCollector.new(filenames, :internal).filenames_per_href

          uris.each_pair do |href, fns|
            fns.each do |filename|
              next if valid?(href, filename)

              add_issue(
                "broken reference to <#{href}>",
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

          # Turn file: into output_dir-as-root relative paths

          output_dir = @config.output_dir
          output_dir += '/' unless output_dir.end_with?('/')
          # FIXME: escape is hacky
          base_uri = URI("file://#{output_dir.gsub(' ', '%20')}")
          path = href.sub(/#{base_uri}/, '').sub(/file:\/{1,3}/, '')

          path = "/#{path}" unless path.start_with?('/')

          # Skip hrefs that are specified in the exclude configuration
          return true if excluded?(path, origin)

          # Make an absolute path
          path = ::File.join(output_dir, path[1..path.length])

          # Remove fragment
          path = path.sub(/#.*$/, '')
          return true if path.empty?

          # Remove query string
          path = path.sub(/\?.*$/, '')
          return true if path.empty?

          # Decode URL (e.g. '%20' -> ' ')
          path = CGI.unescape(path)

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
          # FIXME: do not depend on current working directory
          origin = File.absolute_path(origin)

          relative_origin = origin[@config.output_dir.size..]
          excludes = config.fetch(:exclude_origins, [])
          excludes.any? { |pattern| Regexp.new(pattern).match(relative_origin) }
        end
      end
    end
  end
end
