# encoding: utf-8

module Nanoc3

  # Contains methods that will be executed by the site’s `Rules` file.
  class CompilerDSL

    # Creates a new compiler DSL for the given compiler.
    #
    # @param [Nanoc3::Site] site The site this DSL belongs to
    def initialize(site)
      @site = site
    end

    # Creates a preprocessor block that will be executed after all data is
    # loaded, but before the site is compiled.
    #
    # @yield The block that will be executed before site compilation starts
    #
    # @return [void]
    def preprocess(&block)
      @site.preprocessor = block
    end

    # Creates a compilation rule for all items whose identifier match the
    # given identifier, which may either be a string containing the *
    # wildcard, or a regular expression.
    #
    # This rule will be applicable to reps with a name equal to `:default`;
    # this can be changed by giving an explicit `:rep` parameter.
    #
    # An item rep will be compiled by calling the given block and passing the
    # rep as a block argument.
    #
    # @param [String] identifier A pattern matching identifiers of items that
    # should be compiled using this rule
    #
    # @option params [Symbol] :rep (:default) The name of the representation
    # that should be compiled using this rule
    #
    # @yield The block that will be executed when an item matching this
    # compilation rule needs to be compiled
    #
    # @return [void]
    #
    # @example Compiling the default rep of the `/foo/` item
    #
    #     compile '/foo/' do
    #       rep.filter :erb
    #     end
    #
    # @example Compiling the `:raw` rep of the `/bar/` item
    #
    #     compile '/bar/', :rep => :raw do
    #       # do nothing
    #     end
    def compile(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#compile requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      rule = Rule.new(identifier_to_regex(identifier), rep_name, block)
      @site.compiler.item_compilation_rules << rule
    end

    # Creates a routing rule for all items whose identifier match the
    # given identifier, which may either be a string containing the `*`
    # wildcard, or a regular expression.
    #
    # This rule will be applicable to reps with a name equal to `:default`;
    # this can be changed by giving an explicit `:rep` parameter.
    #
    # The path of an item rep will be determined by calling the given block
    # and passing the rep as a block argument.
    #
    # @param [String] identifier A pattern matching identifiers of items that
    # should be routed using this rule
    #
    # @option params [Symbol] :rep (:default) The name of the representation
    # that should be routed using this rule
    #
    # @yield The block that will be executed when an item matching this
    # compilation rule needs to be routed
    #
    # @return [void]
    #
    # @example Routing the default rep of the `/foo/` item
    #
    #     route '/foo/' do
    #       item.identifier + 'index.html'
    #     end
    #
    # @example Routing the `:raw` rep of the `/bar/` item
    #
    #     route '/bar/', :rep => :raw do
    #       '/raw' + item.identifier + 'index.txt'
    #     end
    def route(identifier, params={}, &block)
      # Require block
      raise ArgumentError.new("#route requires a block") unless block_given?

      # Get rep name
      rep_name = params[:rep] || :default

      # Create rule
      rule = Rule.new(identifier_to_regex(identifier), rep_name, block)
      @site.compiler.item_routing_rules << rule
    end

    # Creates a layout rule for all layouts whose identifier match the given
    # identifier, which may either be a string containing the * wildcard, or a
    # regular expression. The layouts matching the identifier will be filtered
    # using the filter specified in the second argument. The params hash
    # contains filter arguments that will be passed to the filter.
    #
    # @param [String] identifier A pattern matching identifiers of layouts
    # that should be filtered using this rule
    #
    # @param [Symbol] filter_name The name of the filter that should be run
    # when processing the layout
    #
    # @param [Hash] params Extra filter arguments that should be passed to the
    # filter when processing the layout (see {Nanoc3::Filter#run})
    #
    # @return [void]
    #
    # @example Specifying the filter to use for a layout
    #
    #     layout '/default/', :erb
    #
    # @example Using custom filter arguments for a layout
    #
    #     layout '/custom/',  :haml, :format => :html5
    def layout(identifier, filter_name, params={})
      @site.compiler.layout_filter_mapping[identifier_to_regex(identifier)] = [ filter_name, params ]
    end

  private

    # Converts the given identifier, which can contain the '*' or '+'
    # wildcard characters, matching zero or more resp. one or more
    # characters, to a regex. For example, 'foo/*/bar' is transformed
    # into /^foo\/(.*?)\/bar$/ and 'foo+' is transformed into /^foo(.+?)/.
    def identifier_to_regex(identifier)
      if identifier.is_a? String
        # Add leading/trailing slashes if necessary
        new_identifier = identifier.dup
        new_identifier[/^/] = '/' if identifier[0,1] != '/'
        new_identifier[/$/] = '/' unless [ '*', '/' ].include?(identifier[-1,1])

        /^#{new_identifier.gsub('*', '(.*?)').gsub('+', '(.+?)')}$/
      else
        identifier
      end
    end

  end

end
