# frozen_string_literal: true

module Nanoc::RuleDSL
  # Contains methods that will be executed by the site’s `Rules` file.
  #
  # @api private
  class CompilerDSL < Nanoc::Int::Context
    # The current rules filename.
    #
    # @return [String] The current rules filename.
    #
    # @api private
    attr_accessor :rules_filename

    # Creates a new compiler DSL for the given collection of rules.
    #
    # @api private
    #
    # @param [Nanoc::RuleDSL::RulesCollection] rules_collection The collection of
    #   rules to modify when loading this DSL
    #
    # @param [Hash] config The site configuration
    def initialize(rules_collection, config)
      @rules_collection = rules_collection
      @config = config
      super({ config: config })
    end

    # Creates a preprocessor block that will be executed after all data is
    # loaded, but before the site is compiled.
    #
    # @yield The block that will be executed before site compilation starts
    #
    # @return [void]
    def preprocess(&block)
      if @rules_collection.preprocessors[rules_filename]
        warn 'WARNING: A preprocess block is already defined. Defining ' \
          'another preprocess block overrides the previously one.'
      end
      @rules_collection.preprocessors[rules_filename] = block
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
    #   should be compiled using this rule
    #
    # @param [Symbol] rep The name of the representation
    #
    # @yield The block that will be executed when an item matching this
    #   compilation rule needs to be compiled
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
    def compile(identifier, rep: :default, &block)
      raise ArgumentError.new('#compile requires a block') unless block_given?

      rule = Nanoc::RuleDSL::Rule.new(create_pattern(identifier), rep, block)
      @rules_collection.add_item_compilation_rule(rule)
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
    #   should be routed using this rule
    #
    # @param [Symbol] rep The name of the representation
    #
    # @param [Symbol] snapshot The name of the snapshot
    #
    # @yield The block that will be executed when an item matching this
    #   compilation rule needs to be routed
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
    def route(identifier, rep: :default, snapshot: :last, &block)
      raise ArgumentError.new('#route requires a block') unless block_given?

      rule = Nanoc::RuleDSL::Rule.new(create_pattern(identifier), rep, block, snapshot_name: snapshot)
      @rules_collection.add_item_routing_rule(rule)
    end

    # Creates a layout rule for all layouts whose identifier match the given
    # identifier, which may either be a string containing the * wildcard, or a
    # regular expression. The layouts matching the identifier will be filtered
    # using the filter specified in the second argument. The params hash
    # contains filter arguments that will be passed to the filter.
    #
    # @param [String] identifier A pattern matching identifiers of layouts
    #   that should be filtered using this rule
    #
    # @param [Symbol] filter_name The name of the filter that should be run
    #   when processing the layout
    #
    # @param [Hash] params Extra filter arguments that should be passed to the
    #   filter when processing the layout (see {Nanoc::Filter#run})
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
    def layout(identifier, filter_name, params = {})
      pattern = Nanoc::Int::Pattern.from(create_pattern(identifier))
      @rules_collection.layout_filter_mapping[pattern] = [filter_name, params]
    end

    # Creates a pair of compilation and routing rules that indicate that the
    # specified item(s) should be copied to the output folder as-is. The items
    # are selected using an identifier, which may either be a string
    # containing the `*` wildcard, or a regular expression.
    #
    # This meta-rule will be applicable to reps with a name equal to
    # `:default`; this can be changed by giving an explicit `:rep` parameter.
    #
    # @param [String] identifier A pattern matching identifiers of items that
    #   should be processed using this meta-rule
    #
    # @param [Symbol] rep The name of the representation
    #
    # @return [void]
    #
    # @example Copying the `/foo/` item as-is
    #
    #     passthrough '/foo/'
    #
    # @example Copying the `:raw` rep of the `/bar/` item as-is
    #
    #     passthrough '/bar/', :rep => :raw
    def passthrough(identifier, rep: :default)
      raise ArgumentError.new('#passthrough does not require a block') if block_given?

      compilation_block = proc {}
      compilation_rule = Nanoc::RuleDSL::Rule.new(create_pattern(identifier), rep, compilation_block)
      @rules_collection.add_item_compilation_rule(compilation_rule)

      # Create routing rule
      routing_block = proc do
        if item.identifier.full?
          item.identifier.to_s
        else
          # This is a temporary solution until an item can map back to its data
          # source.
          # ATM item[:content_filename] is nil for items coming from the static
          # data source.
          item[:extension].nil? || (item[:content_filename].nil? && item.identifier =~ %r{#{item[:extension]}/$}) ? item.identifier.chop : item.identifier.chop + '.' + item[:extension]
        end
      end
      routing_rule = Nanoc::RuleDSL::Rule.new(create_pattern(identifier), rep, routing_block, snapshot_name: :last)
      @rules_collection.add_item_routing_rule(routing_rule)
    end

    # Creates a pair of compilation and routing rules that indicate that the
    # specified item(s) should be ignored, e.g. compiled and routed with an
    # empty rule. The items are selected using an identifier, which may either
    # be a string containing the `*` wildcard, or a regular expression.
    #
    # This meta-rule will be applicable to reps with a name equal to
    # `:default`; this can be changed by giving an explicit `:rep` parameter.
    #
    # @param [String] identifier A pattern matching identifiers of items that
    #   should be processed using this meta-rule
    #
    # @param [Symbol] rep The name of the representation
    #
    # @return [void]
    #
    # @example Suppressing compilation and output for all all `/foo/*` items.
    #
    #     ignore '/foo/*'
    def ignore(identifier, rep: :default)
      raise ArgumentError.new('#ignore does not require a block') if block_given?

      compilation_rule = Nanoc::RuleDSL::Rule.new(create_pattern(identifier), rep, proc {})
      @rules_collection.add_item_compilation_rule(compilation_rule)

      routing_rule = Nanoc::RuleDSL::Rule.new(create_pattern(identifier), rep, proc {}, snapshot_name: :last)
      @rules_collection.add_item_routing_rule(routing_rule)
    end

    # Includes an additional rules file in the current rules collection.
    #
    # @param [String] name The name of the rules file — an ".rb" extension is
    #   implied if not explicitly given
    #
    # @return [void]
    #
    # @example Including two additional rules files, 'rules/assets.rb' and
    #   'rules/content.rb'
    #
    #     include_rules 'rules/assets'
    #     include_rules 'rules/content'
    def include_rules(name)
      filename = [name.to_s, "#{name}.rb", "./#{name}", "./#{name}.rb"].find { |f| File.file?(f) }
      raise Nanoc::Int::Errors::NoRulesFileFound.new if filename.nil?

      Nanoc::RuleDSL::RulesLoader.new(@config, @rules_collection).parse(filename)
    end

    # Creates a postprocessor block that will be executed after all data is
    # loaded and the site is compiled.
    #
    # @yield The block that will be executed after site compilation completes
    #
    # @return [void]
    def postprocess(&block)
      if @rules_collection.postprocessors[rules_filename]
        warn 'WARNING: A postprocess block is already defined. Defining ' \
          'another postprocess block overrides the previously one.'
      end
      @rules_collection.postprocessors[rules_filename] = block
    end

    # @api private
    def create_pattern(arg)
      case @config[:string_pattern_type]
      when 'glob'
        Nanoc::Int::Pattern.from(arg)
      when 'legacy'
        Nanoc::Int::Pattern.from(identifier_to_regex(arg))
      else
        raise(
          Nanoc::Int::Errors::GenericTrivial,
          "Invalid string_pattern_type: #{@config[:string_pattern_type]}",
        )
      end
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
        new_identifier[/^/] = '/' if identifier[0, 1] != '/'
        new_identifier[/$/] = '/?' unless ['*', '/'].include?(identifier[-1, 1])

        regex_string =
          new_identifier
          .gsub('.', '\.')
          .gsub('*', '(.*?)')
          .gsub('+', '(.+?)')

        /^#{regex_string}$/
      else
        identifier
      end
    end
  end
end
