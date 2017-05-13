# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class Site
    include Nanoc::Int::ContractsSupport

    attr_reader :code_snippets
    attr_reader :config
    attr_accessor :data_source
    attr_accessor :compiler

    contract C::KeywordArgs[config: Nanoc::Int::Configuration, code_snippets: C::IterOf[Nanoc::Int::CodeSnippet], data_source: C::Maybe[C::Named['Nanoc::DataSource']]] => C::Any
    def initialize(config:, code_snippets:, data_source:)
      @config = config
      @code_snippets = code_snippets
      @data_source = data_source

      ensure_identifier_uniqueness(@data_source.items, 'item')
      ensure_identifier_uniqueness(@data_source.layouts, 'layout')
    end

    contract C::None => self
    def compile
      compiler.run_all
      self
    end

    contract C::None => C::Named['Nanoc::Int::Compiler']
    def compiler
      @compiler ||= Nanoc::Int::CompilerLoader.new.load(self)
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

    contract C::IterOf[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]], String => self
    def ensure_identifier_uniqueness(objects, type)
      seen = Set.new
      objects.each do |obj|
        if seen.include?(obj.identifier)
          raise Nanoc::Int::Errors::DuplicateIdentifier.new(obj.identifier, type)
        end
        seen << obj.identifier
      end
      self
    end
  end
end
