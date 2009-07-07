# encoding: utf-8

module Nanoc3

  # Nanoc3::CompilerDSL contains methods that will be executed by the site's
  # rules file.
  class CompilerDSL

    # Creates a new compiler DSL for the given compiler.
    def initialize(compiler)
      @compiler = compiler
    end

    # Creates a compilation rule for all items whose identifier match the
    # given identifier, which may either be a string containing the *
    # wildcard, or a regular expression.
    #
    # This rule will be applicable to reps with a name equal to "default"
    # unless an explicit :rep parameter is given.
    #
    # An item rep will be compiled by calling the given block and passing the
    # rep as a block argument.
    #
    # Example:
    #
    #   compile '/foo/*' do |rep|
    #     rep.filter :erb
    #   end
    #   
    #   compile '/bar/*', :rep => 'raw' do |rep|
    #     # do nothing
    #   end
    def compile(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#compile requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      rule = Rule.new(identifier_to_regex(identifier), rep_name, block)
      @compiler.item_compilation_rules << rule
    end

    # Creates a routing rule for all items whose identifier match the
    # given identifier, which may either be a string containing the *
    # wildcard, or a regular expression.
    #
    # This rule will be applicable to reps with a name equal to "default";
    # this can be changed by givign an explicit :rep parameter.
    #
    # The path of an item rep will be determined by calling the given block
    # and passing the rep as a block argument.
    #
    # Example:
    #
    #   route '/foo/*' do |rep|
    #     '/blahblah' + rep.item.identifier + 'index.html'
    #   end
    #   
    #   route '/bar/*', :rep => 'raw' do |rep|
    #     '/blahblah' + rep.item.identifier + 'index.txt'
    #   end
    def route(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#route requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      rule = Rule.new(identifier_to_regex(identifier), rep_name, block)
      @compiler.item_routing_rules << rule
    end

    # Creates a layout rule for all layouts whose identifier match the first
    # key in the given hash (which should only contain one key-value pair).
    # The value of the first pair is the filter to use when compiling this
    # layout.
    #
    # Example:
    #
    #   layout '/default/' => :erb
    #   layout '/custom/'  => :haml
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
