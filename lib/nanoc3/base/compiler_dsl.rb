# encoding: utf-8

module Nanoc3

  class CompilerDSL

    def initialize(compiler)
      @compiler = compiler
    end

    # TODO document
    def compile(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#compile requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      rule = ItemRule.new(identifier_to_regex(identifier), rep_name, block)
      @compiler.item_compilation_rules << rule
    end

    # TODO document
    def route(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#route requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      rule = ItemRule.new(identifier_to_regex(identifier), rep_name, block)
      @compiler.item_routing_rules << rule
    end

    # TODO document
    def layout(params={})
      # Get layout identifier and filter name
      identifier  = params.keys[0]
      filter_name = params.values[0]

      # Create rule
      @compiler.layout_filter_mapping[identifier_to_regex(identifier)] = filter_name
    end

  private

    # Converts the given identifier, which can contain the '*' wildcard, to a regex.
    # For example, 'foo/*/bar' is transformed into /^foo\/(.*?)\/bar$/.
    def identifier_to_regex(identifier)
      if identifier.is_a? String
        /^#{identifier.gsub('*', '(.*?)')}$/
      else
        identifier
      end
    end

  end

end
