module Nanoc

  # Nanoc::Compiler is responsible for compiling a site's page and asset
  # representations.
  class Compiler

    attr_reader :stack

    # Creates a new compiler for the given site.
    # FIXME compiler doesn't need to know about the site
    def initialize(site)
      @site = site

      @page_rules  = []
      @asset_rules = []
    end

    # Compiles (part of) the site and writes out the compiled page and asset
    # representations.
    #
    # +obj+:: The page or asset that should be compiled, along with their
    #         dependencies, or +nil+ if the entire site should be compiled.
    #
    # This method also accepts a few parameters:
    #
    # +:force+:: true if the rep should be compiled even if
    #                             it is not outdated, false if not. Defaults
    #                             to false.
    def run(objects=nil, params={})
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

      # Initialize
      @stack = []

      # Get pages and asset reps
      objects = @site.pages + @site.assets if objects.nil?
      reps = objects.map { |o| o.reps }.flatten

      # Compile everything
      reps.each { |rep| compile_rep(rep, force) }
    end

    # Compiles the given item representation. This method should not be called
    # directly; please use Nanoc::Compiler#run instead, and pass this item
    # representation's item as its first argument.
    #
    # +rep+:: The rep that is to be compiled.
    #
    # +force+:: true if the item rep should be compiled even if it is not
    #                            outdated, false if not.
    def compile_rep(rep, force)
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
      old_content = File.file?(rep.disk_path) ? File.read(rep.disk_path) : nil

      # Find and apply matching page rule
      rules = (rep.type == :page_rep ? @page_rules : @asset_rules)
      rule = rules.find { |r| r.applicable_to?(rep) }
      raise Nanoc::Errors::NoMatchingRuleFoundError.new if rule.nil?
      rule.apply_to(rep)

      # Update status
      rep.compiled = true
      unless rep.attribute_named(:skip_output)
        rep.created  = old_content.nil?
        rep.modified = rep.created ? true : old_content != rep.content[:last]
      end

      # Stop
      Nanoc::NotificationCenter.post(:compilation_ended, rep)
      @stack.pop
    end

    def add_page_rule(path, block)
      @page_rules << ItemRule.new(path_to_regex(path), self, block)
    end

    def add_asset_rule(path, block)
      @asset_rules << ItemRule.new(path_to_regex(path), self, block)
    end

    def add_layout_rule(path, block)
      # TODO implement
    end

  private

    # TODO document
    def path_to_regex(path)
      if path.is_a? String
        /^#{path.gsub('*', '(.*?)')}$/
      else
        path
      end
    end

  end

end
