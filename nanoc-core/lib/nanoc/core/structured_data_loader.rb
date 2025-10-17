# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    module StructuredDataLoader
      class UnknownLanguageError < StandardError
        def initialize(lang)
          super("cannot find loader for language: #{lang.inspect}")
        end
      end

      def self.for_language(language)
        case language
        when :yaml
          YamlLoader
        when :toml
          TomlLoader
        else
          raise UnknownLanguageError.enw(language)
        end
      end

      def self.for_extension(ext)
        case ext
        when '.yaml'
          YamlLoader
        when '.toml'
          TomlLoader
        else
          raise UnknownLanguageError.enw(language)
        end
      end
    end
  end
end
