# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class Site
      # Error that is raised when multiple items or layouts with the same identifier exist.
      class DuplicateIdentifierError < ::Nanoc::Core::Error
        def initialize(identifier, type)
          super("There are multiple #{type}s with the #{identifier} identifier.")
        end
      end

      include Nanoc::Core::ContractsSupport

      attr_reader :code_snippets
      attr_reader :config
      attr_accessor :data_source

      contract C::KeywordArgs[config: Nanoc::Core::Configuration, code_snippets: C::IterOf[Nanoc::Core::CodeSnippet], data_source: C::Named['Nanoc::Core::DataSource']] => C::Any
      def initialize(config:, code_snippets:, data_source:)
        @config = config
        @code_snippets = code_snippets
        @data_source = data_source

        @preprocessed = false

        ensure_identifier_uniqueness(@data_source.items, 'item')
        ensure_identifier_uniqueness(@data_source.layouts, 'layout')
      end

      def mark_as_preprocessed
        @preprocessed = true
      end

      def preprocessed?
        @preprocessed
      end

      def items
        @data_source.items
      end

      def layouts
        @data_source.layouts
      end

      contract C::None => self
      def freeze
        config.freeze
        items.freeze
        layouts.freeze
        code_snippets.__nanoc_freeze_recursively
        self
      end

      contract C::IterOf[C::Or[Nanoc::Core::Item, Nanoc::Core::Layout]], String => self
      def ensure_identifier_uniqueness(objects, type)
        seen = Set.new
        objects.each do |obj|
          if seen.include?(obj.identifier)
            raise DuplicateIdentifierError.new(obj.identifier, type)
          end

          seen << obj.identifier
        end
        self
      end
    end
  end
end
