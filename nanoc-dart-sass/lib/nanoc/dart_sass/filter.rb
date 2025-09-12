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
          **params,
          importers: [NanocImporter.new(@items)].concat(params.fetch(:importers, [])),
          syntax:,
          url: Addressable::URI.new({ scheme: 'nanoc', path: item.identifier.to_s }).to_s,
        )
        result.css
      end

      class NanocImporter
        def initialize(items)
          @items = items
        end

        def canonicalize(url, context)
          uri = Addressable::URI.parse(context.containing_url).join(url)
          return unless uri.scheme == 'nanoc'

          resolved = resolve_path(uri.path, context.from_import)
          Addressable::URI.new({ scheme: 'nanoc', path: resolved }).to_s unless resolved.nil?
        end

        def load(url)
          uri = Addressable::URI.parse(url)
          item = @items[uri.path]

          {
            contents: item.raw_content,
            syntax: Util.syntax_from_ext(item.identifier.ext),
          }
        end

        private

        # https://github.com/sass-contrib/sassc-embedded-shim-ruby/blob/594632bb896fb765462253b16ea0451f5f93316d/lib/sassc/embedded.rb#L228
        def resolve_path(path, from_import)
          ext = File.extname(path)
          if ext == '.*'
            if from_import
              result = exactly_one(try_path_with_ext("#{without_ext(path)}.import") + try_path_with_ext("#{path}.import"))
              return result unless result.nil?
            end

            result = exactly_one(try_path_with_ext(without_ext(path)) + try_path_with_ext(path))
            return result unless result.nil?

            return try_path_as_dir(path, from_import)
          end

          if ['.sass', '.scss', '.css'].include?(ext)
            if from_import
              result = exactly_one(try_path("#{without_ext(path)}.import#{ext}"))
              return result unless result.nil?
            end
            return exactly_one(try_path(path))
          end

          if from_import
            result = exactly_one(try_path_with_ext("#{path}.import"))
            return result unless result.nil?
          end

          result = exactly_one(try_path_with_ext(path))
          return result unless result.nil?

          try_path_as_dir(path, from_import)
        end

        def try_path_with_ext(path)
          result = try_path("#{path}.sass") + try_path("#{path}.scss")
          result.empty? ? try_path("#{path}.css") : result
        end

        def try_path(path)
          partial = File.join(File.dirname(path), "_#{File.basename(path)}")
          result = []
          result.concat(@items.find_all(partial).map(&:identifier).map(&:to_s))
          result.concat(@items.find_all(path).map(&:identifier).map(&:to_s))
          result
        end

        def try_path_as_dir(path, from_import)
          if from_import
            result = exactly_one(try_path_with_ext(File.join(path, 'index.import')))
            return result unless result.nil?
          end

          exactly_one(try_path_with_ext(File.join(path, 'index')))
        end

        def exactly_one(paths)
          return if paths.empty?
          return paths.first if paths.one?

          raise "It's not clear which file to import. Found:\n#{paths.map { |path| "  #{path}" }.join("\n")}"
        end

        def without_ext(path)
          ext = File.extname(path)
          path.delete_suffix(ext)
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
