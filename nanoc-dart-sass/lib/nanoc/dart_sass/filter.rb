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
        syntax ||=
          case item.identifier.ext
          when 'sass'
            :indented
          when 'scss'
            :scss
          when 'css'
            :css
          else
            nil
          end

        result = Sass.compile_string(
          content,
          importer: NanocImporter.new(@items),
          **params,
          syntax: syntax,
        )
        result.css
      rescue StandardError => e
        # TODO: use full_message for syntax errors
        raise e
      end

      class NanocImporter
        def initialize(items)
          @items = items
        end

        def canonicalize(url, **)
          "nanoc:#{@items[url.sub(/\Ananoc:/, '')].identifier}"
        end

        def load(url)
          item = @items[url.sub(/\Ananoc:/, '')]
          {
            contents: item.raw_content,
            syntax: item.identifier.ext,
          }
        end
      end

      private_constant :NanocImporter
    end
  end
end
