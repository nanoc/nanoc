# frozen_string_literal: true

module Nanoc
  module DartSass
    class Filter < Nanoc::Filter
      identifier :dart_sass

      # Runs the content through [Dart Sass](https://sass-lang.com/dart-sass).
      # Parameters passed as `:args` will be passed on to Dart Sass.
      #
      # @param [String] content The content to filter
      #
      # @return [String] The filtered content
      def run(content, params = {})
        # Read syntax
        syntax = params[:syntax]
        syntax ||= Util.syntax_from_ext(item.identifier.ext)

        result = Sass.compile_string(
          content,
          importer: NanocImporter.new(@items, item),
          **params,
          syntax: syntax,
        )
        result.css
      rescue StandardError => e # rubocop:disable Lint/UselessRescue
        # TODO: use full_message for syntax errors
        raise e
      end

      class NanocImporter
        def initialize(items, source_item)
          @items = items
          @source_item = source_item
        end

        def canonicalize(url, **)
          # Construct proper URL with `nanoc:` prefix if needed
          if url.start_with?('nanoc:')
            url
          else
            "nanoc:#{url}"
          end
        end

        def load(url)
          item = find_item_for_url(url)

          {
            contents: item.raw_content,
            syntax: Util.syntax_from_ext(item.identifier.ext),
          }
        end

        private

        def find_item_for_url(url)
          pat = url.sub(/\Ananoc:/, '')

          # If URL has no extension, add `.*` at the end
          if pat.match?(%r{(/|^)[^.]+$})
            pat += '.*'
          end

          # Convert to absolute pattern
          pat =
            if pat.start_with?('/')
              pat
            else
              dirname = File.dirname(@source_item.identifier.to_s)
              File.expand_path(pat, dirname)
            end

          item = @items[pat]

          unless item
            raise "Could not find an item matching pattern `#{pat}`"
          end

          item
        end
      end

      module Util
        module_function

        def syntax_from_ext(ext)
          case ext
          when 'sass'
            :indented
          when 'scss'
            :scss
          when 'css'
            :css
          else
            nil
          end
        end
      end

      private_constant :Util
    end
  end
end
