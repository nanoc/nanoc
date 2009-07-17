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

    # Creates a layout rule for all layouts whose identifier match the given
    # identifier, which may either be a string containing the * wildcard, or a
    # regular expression. The layouts matching the identifier will be filtered
    # using the filter specified in the second argument. The params hash
    # contains filter arguments that will be passed to the filter.
    #
    # Example:
    #
    #   layout '/default/', :erb
    #   layout '/custom/',  :haml, :format => :html5
    def layout(identifier, filter_name, params={})
      @compiler.layout_filter_mapping[identifier_to_regex(identifier)] = [ filter_name, params ]
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
