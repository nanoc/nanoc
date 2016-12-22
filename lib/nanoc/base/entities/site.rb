module Nanoc::Int
  # @api private
  class Site
    include Nanoc::Int::ContractsSupport

    attr_accessor :compiler

    contract C::KeywordArgs[config: Nanoc::Int::Configuration, code_snippets: C::IterOf[Nanoc::Int::CodeSnippet], items: C::IterOf[Nanoc::Int::Item], layouts: C::IterOf[Nanoc::Int::Layout]] => C::Any
    def initialize(config:, code_snippets:, items:, layouts:)
      @config = config
      @code_snippets = code_snippets
      @items = items
      @layouts = layouts

      ensure_identifier_uniqueness(@items, 'item')
      ensure_identifier_uniqueness(@layouts, 'layout')
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

    attr_reader :code_snippets
    attr_reader :config
    attr_reader :items
    attr_reader :layouts

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
