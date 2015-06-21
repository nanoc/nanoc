module Nanoc::Int
  # @api private
  class Site
    # @option params [Nanoc::Int::Configuration] :config
    #
    # @option params [Enumerable<Nanoc::Int::CodeSnippet>] :code_snippets
    def initialize(params = {})
      @config = params.fetch(:config)
      @code_snippets = params.fetch(:code_snippets)
      @items = params.fetch(:items)
      @layouts = params.fetch(:layouts)

      ensure_identifier_uniqueness(@items, 'item')
      ensure_identifier_uniqueness(@layouts, 'layout')
    end

    # Compiles the site.
    #
    # @return [void]
    #
    # @since 3.2.0
    def compile
      compiler.run_all
    end

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

    # Prevents all further modifications to itself, its items, its layouts etc.
    #
    # @return [void]
    def freeze
      config.__nanoc_freeze_recursively
      items.each(&:freeze)
      layouts.each(&:freeze)
    end

    def ensure_identifier_uniqueness(objects, type)
      seen = Set.new
      objects.each do |obj|
        if seen.include?(obj.identifier)
          raise Nanoc::Int::Errors::DuplicateIdentifier.new(obj.identifier, type)
        end
        seen << obj.identifier
      end
    end
  end
end
