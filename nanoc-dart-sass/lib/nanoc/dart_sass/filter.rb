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
          importer: make_dart_sass_importer(@items),
          **params,
          syntax: syntax,
        )
        result.css
      rescue StandardError => e
        # TODO: use full_message for syntax errors
        raise e
      end

      private

      def make_dart_sass_importer(items)
        {
          canonicalize: lambda do |param, **|
            "nanoc:#{items[param.sub(/\Ananoc:/, '')].identifier}"
          end,
          load: lambda { |url|
            param = url.sub(/\Ananoc:/, '')
            item = items[param]
            return {
              contents: item.raw_content,
              syntax: item.identifier.ext,
            }
          },
        }
      end
    end
  end
end
