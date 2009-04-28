module Nanoc3

  # Nanoc3::Compiler is responsible for compiling a site's item
  # representations.
  class Compiler

    # The compilation stack. When the compiler begins compiling a rep, it will
    # be placed on the stack; when it is done compiling the rep, it will be
    # removed from the stack.
    attr_reader :stack

    # Creates a new compiler for the given site.
    def initialize(site)
      @site = site

      @stack = []

      @item_compilation_rules  = []
      @layout_filter_mapping   = {}
    end

    # Compiles (part of) the site and writes out the compiled item
    # representations.
    #
    # +items+:: The items that should be compiled, along with their
    #           dependencies. Pass +nil+ if the entire site should be
    #           compiled.
    #
    # This method also accepts a few optional parameters:
    #
    # +:force+:: true if the rep should be compiled even if it is not
    #            outdated, false if not. Defaults to false.
    def run(items=nil, params={})
      # Load rules
      load_rules

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Get items
      @items = items || @site.items

      # Build reps
      @items.each { |i| build_reps_for(i) }
      @reps = @items.map { |i| i.reps }.flatten

      # Map reps
      @reps.each { |r| map_rep(r) }

      # Mark all reps as outdated if necessary
      if params.has_key?(:force) && params[:force]
        @reps.each { |r| r.force_outdated = true }
      end

      # Compile reps
      @stack = []
      @reps.each { |rep| compile_rep(rep) }
    end

    # Loads the DSL rules from the rules file in the site's directory.
    #
    # This method should not be called directly; please use
    # Nanoc3::Compiler#run instead, and pass this item representation's item as
    # its first argument.
   def load_rules
      # Find rules file
      rules_filename = [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].find { |f| File.file?(f) }
      raise Nanoc3::Errors::NoRulesFileFoundError.new if rules_filename.nil?

      # Initialize rules
      @item_compilation_rules  = []

      # Load DSL
      dsl = Nanoc3::CompilerDSL.new(self)
      dsl.instance_eval(File.read(rules_filename), rules_filename)
    end

    # Builds the representations for thet given item.
    #
    # This method should not be called directly; please use
    # Nanoc3::Compiler#run instead, and pass this item representation's item as
    # its first argument.
    def build_reps_for(item)
      # Find matching rules
      all_rules = @item_compilation_rules
      matching_rules = all_rules.select { |r| r.applicable_to?(item) }
      raise Nanoc3::Errors::NoMatchingCompilationRuleFoundError.new("#{rep.item.path} (rep #{rep.name})") if matching_rules.empty?

      # Build reps
      rep_names = matching_rules.map { |r| r.rep_name }.uniq
      rep_names.each do |rep_name|
        item.reps << ItemRep.new(item, rep_name)
      end
    end

    # Gives the given rep a disk path and a web path.
    #
    # This method should not be called directly; please use
    # Nanoc3::Compiler#run instead, and pass this item representation's item as
    # its first argument.
    def map_rep(rep)
      # TODO use mapping rules instead of using the router

      rep.raw_path = @site.router.raw_path_for(rep)
      rep.path     = @site.router.path_for(rep)
    end

    # Compiles the given item representation.
    #
    # This method should not be called directly; please use
    # Nanoc3::Compiler#run instead, and pass this item representation's item as
    # its first argument.
    #
    # +rep+:: The rep that is to be compiled.
    def compile_rep(rep)
      # Don't compile if already compiled
      return if rep.compiled?

      # Skip unless outdated
      unless rep.outdated?
        Nanoc3::NotificationCenter.post(:compilation_started, rep)
        Nanoc3::NotificationCenter.post(:compilation_ended,   rep)
        return
      end

      # Check for recursive call
      if @stack.include?(rep)
        @stack.push(rep)
        raise Nanoc3::Errors::RecursiveCompilationError.new
      end

      # Start
      @stack.push(rep)
      Nanoc3::NotificationCenter.post(:compilation_started, rep)

      # Apply matching rule
      compilation_rule_for(rep).apply_to(rep)
      rep.compiled = true

      # Stop
      Nanoc3::NotificationCenter.post(:compilation_ended, rep)
      @stack.pop
    end

    # Returns the compilation rule for the given rep.
    def compilation_rule_for(rep)
      @item_compilation_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Returns the filter name for the given layout
    def filter_name_for_layout(layout)
      filter_name = nil
      @layout_filter_mapping.each_pair do |lr, fn|
        filter_name = fn if layout.identifier =~ lr
      end
      filter_name
    end

    # Adds an item compilation rule to the compiler.
    #
    # +identifier+:: The identifier for the item that should be compiled using
    #                this rule. Can contain the '*' wildcard, which matches
    #                zero or more characters.
    #
    # +rep_name+:: The name of the representation this compilation rule
    #              applies to.
    #
    # +block+:: A Proc that should be used to compile the matching items.
    def add_item_compilation_rule(identifier, rep_name, block)
      @item_compilation_rules << ItemRule.new(identifier_to_regex(identifier), rep_name, self, block)
    end

    # Adds a layout compilation rule to the compiler.
    #
    # +identifier+:: The identifier for the layout that should be compiled
    #                using this rule. Can contain the '*' wildcard, which
    #                matches zero or more characters.
    #
    # +filter_name+:: The name of the filter that should be used to compile
    #                 the matching layouts.
    def add_layout_compilation_rule(identifier, filter_name)
      @layout_filter_mapping[identifier_to_regex(identifier)] = filter_name
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
