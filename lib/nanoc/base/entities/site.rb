module Nanoc::Int
  # @api private
  class Site
    include Contracts::Core

    C = Contracts

    attr_accessor :compiler

    Contract C::KeywordArgs[config: Nanoc::Int::Configuration, code_snippets: C::RespondTo[:each], items: C::RespondTo[:each], layouts: C::RespondTo[:each]] => C::Any
    # @param [Nanoc::Int::Configuration] config
    # @param [Enumerable<Nanoc::Int::CodeSnippet>] code_snippets
    # @param [Enumerable<Nanoc::Int::Item>] items
    # @param [Enumerable<Nanoc::Int::Layout>] layouts
    def initialize(config:, code_snippets:, items:, layouts:)
      @config = config
      @code_snippets = code_snippets
      @items = items
      @layouts = layouts

      ensure_identifier_uniqueness(@items, 'item')
      ensure_identifier_uniqueness(@layouts, 'layout')
    end

    Contract C::None => self
    # Compiles the site.
    #
    # @return [void]
    #
    # @since 3.2.0
    def compile
      compiler.run_all
      self
    end

    Contract C::None => Nanoc::Int::Compiler
    # Returns the compiler for this site. Will create a new compiler if none
    # exists yet.
    #
    # @return [Nanoc::Int::Compiler] The compiler for this site
    def compiler
      @compiler ||= Nanoc::Int::CompilerLoader.new.load(self)
    end

    attr_reader :code_snippets
    attr_reader :config
    attr_reader :items
    attr_reader :layouts

    Contract C::None => self
    # Prevents all further modifications to itself, its items, its layouts etc.
    #
    # @return [void]
    def freeze
      config.freeze
      items.freeze
      layouts.freeze
      code_snippets.__nanoc_freeze_recursively
      self
    end

    Contract C::RespondTo[:each], String => self
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
