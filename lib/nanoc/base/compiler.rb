module Nanoc

  # Nanoc::Compiler is responsible for compiling a site's page and asset
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

      @page_compilation_rules  = []
      @asset_compilation_rules = []
      @layout_filter_mapping   = {}
    end

    # Compiles (part of) the site and writes out the compiled page and asset
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
      @items = items ? items : @site.pages + @site.assets

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
    # Nanoc::Compiler#run instead, and pass this item representation's item as
    # its first argument.
   def load_rules
      # Find rules file
      rules_filename = [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].find { |f| File.file?(f) }
      raise Nanoc::Errors::NoRulesFileFoundError.new if rules_filename.nil?

      # Initialize rules
      @page_compilation_rules  = []
      @asset_compilation_rules = []

      # Load DSL
      dsl = Nanoc::CompilerDSL.new(self)
      dsl.instance_eval(File.read(rules_filename), rules_filename)
    end

    # Builds the representations for thet given item.
    #
    # This method should not be called directly; please use
    # Nanoc::Compiler#run instead, and pass this item representation's item as
    # its first argument.
    def build_reps_for(item)
      # Find matching rules
      all_rules = (item.is_a?(Nanoc::Page) ? @page_compilation_rules : @asset_compilation_rules)
      matching_rules = all_rules.select { |r| r.applicable_to?(item) }
      raise Nanoc::Errors::NoMatchingCompilationRuleFoundError.new("#{rep.item.path} (rep #{rep.name})") if matching_rules.empty?

      # Build reps
      rep_names = matching_rules.map { |r| r.rep_name }.uniq
      rep_names.each do |rep_name|
        if item.is_a?(Nanoc::Page)
          item.reps << PageRep.new(item, rep_name)
        else
          item.reps << AssetRep.new(item, rep_name)
        end
      end
    end

    # Gives the given rep a disk path and a web path.
    #
    # This method should not be called directly; please use
    # Nanoc::Compiler#run instead, and pass this item representation's item as
    # its first argument.
    def map_rep(rep)
      # TODO use mapping rules instead of using the router

      rep.raw_path = @site.router.raw_path_for(rep)
      rep.path     = @site.router.path_for(rep)
    end

    # Compiles the given item representation.
    #
    # This method should not be called directly; please use
    # Nanoc::Compiler#run instead, and pass this item representation's item as
    # its first argument.
    #
    # +rep+:: The rep that is to be compiled.
    def compile_rep(rep)
      # Don't compile if already compiled
      return if rep.compiled?

      # Skip unless outdated
      unless rep.outdated?
        Nanoc::NotificationCenter.post(:compilation_started, rep)
        Nanoc::NotificationCenter.post(:compilation_ended,   rep)
        return
      end

      # Check for recursive call
      if @stack.include?(rep)
        @stack.push(rep)
        raise Nanoc::Errors::RecursiveCompilationError.new
      end

      # Start
      @stack.push(rep)
      Nanoc::NotificationCenter.post(:compilation_started, rep)

      # Apply matching rule
      compilation_rule_for(rep).apply_to(rep)
      rep.compiled = true

      # Stop
      Nanoc::NotificationCenter.post(:compilation_ended, rep)
      @stack.pop
    end

    # Returns the compilation rule for the given rep.
    def compilation_rule_for(rep)
      (rep.is_a?(Nanoc::PageRep) ? @page_compilation_rules : @asset_compilation_rules).find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Returns the filter for the given layout.
    def filter_class_for_layout(layout)
      # FIXME this should not raise any exceptions

      # Get filter name
      filter_name = nil
      @layout_filter_mapping.each_pair do |lr, fn|
        filter_name = fn if layout.identifier =~ lr
      end
      raise Nanoc::Errors::CannotDetermineFilterError.new(layout.identifier) if filter_name.nil?

      # Get filter
      filter_class = Nanoc::Filter.named(filter_name)
      raise Nanoc::Errors::UnknownFilterError.new(filter_name) if filter_class.nil?
      filter_class
    end

    def add_page_compilation_rule(identifier, rep_name, block)
      @page_compilation_rules << ItemRule.new(identifier_to_regex(identifier), rep_name, self, block)
    end

    def add_asset_compilation_rule(identifier, rep_name, block)
      @asset_compilation_rules << ItemRule.new(identifier_to_regex(identifier), rep_name, self, block)
    end

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
