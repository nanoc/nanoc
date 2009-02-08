module Nanoc

  # Nanoc::Compiler is responsible for compiling a site's page and asset
  # representations.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    def initialize(site)
      @site = site

      @stack = []

      @page_rules  = []
      @asset_rules = []
    end

    # Compiles (part of) the site and writes out the compiled page and asset
    # representations.
    #
    # +items+:: The items that should be compiled, along with their
    #           edpendencies. Pass +nil+ if the entire site should be
    #           compiled.
    #
    # This method also accepts a few parameters:
    #
    # +:force+:: true if the rep should be compiled even if it is not
    #                             outdated, false if not. Defaults to false.
    def run(items=nil, params={})
      # Parse params
      force = params[:force] || false

      # Find rules file
      rules_filename = [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].find { |f| File.file?(f) }
      raise Nanoc::Errors::NoRulesFileFoundError.new if rules_filename.nil?

      # Load DSL
      dsl = Nanoc::CompilerDSL.new(self)
      eval(File.read(rules_filename), dsl.get_binding, rules_filename)

      # Load data
      @site.load_data

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Get items to compile
      items ||= @site.pages + @site.assets

      # Compile everything
      @stack = []
      items.each { |i| compile_item(i, force) }
    end

    # Compiles the given item and all its representations. This method should
    # not be called directly; please use Nanoc::Compiler#run instead, and pass
    # the items to compile as the first argument.
    #
    # +force+:: true if the item rep should be compiled even if it is not
    #                            outdated, false if not.
    def compile_item(item, force)
      # Find matching rules
      all_rules = (item.type == :page ? @page_rules : @asset_rules)
      matching_rules = all_rules.inject({}) do |memo, rule|
        # Skip rule if an existing rule for this rep name already exists
        next unless memo[rule.rep_name].nil?

        # Skip rule if not applicable to this rep
        next unless rule.applicable_to?(item)

        # Add rule
        memo.merge({ rule.rep_name => rule })
      end
      raise Nanoc::Errors::NoMatchingRuleFoundError.new if matching_rules.keys.empty?

      # Create reps for each rep name
      rep_names = matching_rules.keys
      reps = rep_names.map do |rep_name|
        if item.type == :page
          PageRep.new(item, rep_name)
        else
          AssetRep.new(item, rep_name)
        end
      end

      # Compile reps
      reps.each { |rep| compile_rep(rep, matching_rules[rep.name.to_sym], force) }
    end

    # Compiles the given item representation. This method should not be called
    # directly; please use Nanoc::Compiler#run instead, and pass this item
    # representation's item as its first argument.
    #
    # +rep+:: The rep that is to be compiled.
    #
    # +force+:: true if the item rep should be compiled even if it is not
    #                            outdated, false if not.
    def compile_rep(rep, rule, force)
      # Reset compilation status
      rep.modified = false
      rep.created  = false

      # Don't compile if already compiled
      return if rep.compiled?

      # Skip unless outdated
      unless rep.outdated? or force
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

      # Create raw and last snapshots if necessary
      rep.content[:raw]  ||= rep.item.content
      rep.content[:last] ||= rep.content[:raw]

      # Check if file will be created
      # FIXME temporary
      old_content = '' # File.file?(rep.disk_path) ? File.read(rep.disk_path) : nil

      # Apply matching rule
      rule.apply_to(rep)

      # Update status
      rep.compiled = true
      unless rep.item.attribute_named(:skip_output)
        rep.created  = old_content.nil?
        rep.modified = rep.created ? true : old_content != rep.content[:last]
      end

      # Stop
      Nanoc::NotificationCenter.post(:compilation_ended, rep)
      @stack.pop
    end

    def add_page_rule(path, rep_name, block)
      @page_rules << ItemRule.new(path_to_regex(path), rep_name, self, block)
    end

    def add_asset_rule(path, rep_name, block)
      @asset_rules << ItemRule.new(path_to_regex(path), rep_name, self, block)
    end

    def add_layout_rule(path, block)
      # TODO implement
    end

  private

    # Converts the given path, which can contain the '*' wildcard, to a regex.
    # For example, 'foo/*/bar' is transformed into /^foo\/(.*?)\/bar$/.
    def path_to_regex(path)
      if path.is_a? String
        /^#{path.gsub('*', '(.*?)')}$/
      else
        path
      end
    end

  end

end
