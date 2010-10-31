# encoding: utf-8

module Nanoc3

  # Responsible for compiling a site’s item representations.
  #
  # The compilation process makes use of notifications (see
  # {Nanoc3::NotificationCenter}) to track dependencies between items,
  # layouts, etc. The following notifications are used:
  #
  # * `compilation_started` — indicates that the compiler has started
  #   compiling this item representation. Has one argument: the item
  #   representation itself. Only one item can be compiled at a given moment;
  #   therefore, it is not possible to get two consecutive
  #   `compilation_started` notifications without also getting a
  #   `compilation_ended` notification in between them.
  #
  # * `compilation_ended` — indicates that the compiler has finished compiling
  #   this item representation (either successfully or with failure). Has one
  #   argument: the item representation itself.
  #
  # * `visit_started` — indicates that the compiler requires content or
  #   attributes from the item representation that will be visited. Has one
  #   argument: the visited item identifier. This notification is used to
  #   track dependencies of items on other items; a `visit_started` event
  #   followed by another `visit_started` event indicates that the item
  #   corresponding to the former event will depend on the item from the
  #   latter event.
  #
  # * `visit_ended` — indicates that the compiler has finished visiting the
  #   item representation and that the requested attributes or content have
  #   been fetched (either successfully or with failure)
  #
  # * `processing_started` — indicates that the compiler has started
  #   processing the specified object, which can be an item representation
  #   (when it is compiled) or a layout (when it is used to lay out an item
  #   representation or when it is used as a partial)
  #
  # * `processing_ended` — indicates that the compiler has finished processing
  #   the specified object.
  class Compiler

    # @group Accessors

    # @return [Nanoc3::Site] The site this compiler belongs to
    attr_reader :site

    # The compilation stack. When the compiler begins compiling a rep or a
    # layout, it will be placed on the stack; when it is done compiling the
    # rep or layout, it will be removed from the stack.
    #
    # @return [Array] The compilation stack
    attr_reader :stack

    # @return [Array<Nanoc3::Rule>] The list of item compilation rules that
    #   will be used to compile items.
    attr_reader :item_compilation_rules

    # @return [Array<Nanoc3::Rule>] The list of routing rules that will be
    #   used to give all items a path.
    attr_reader :item_routing_rules

    # The hash containing layout-to-filter mapping rules. This hash is
    # ordered: iterating over the hash will happen in insertion order.
    #
    # @return [Hash] The layout-to-filter mapping rules
    attr_reader :layout_filter_mapping

    # @return [Proc] The code block that will be executed after all data is
    #   loaded but before the site is compiled
    attr_accessor :preprocessor

    # @group Public instance methods

    # Creates a new compiler fo the given site
    #
    # @param [Nanoc3::Site] site The site this compiler belongs to
    def initialize(site)
      @site = site

      @stack = []

      @item_compilation_rules  = []
      @item_routing_rules      = []
      @layout_filter_mapping   = OrderedHash.new
    end

    # Compiles the site and writes out the compiled item representations.
    #
    # Previous versions of nanoc (< 3.2) allowed passing items to compile, and
    # had a “force” option to make the compiler recompile all pages, even
    # when not outdated. These arguments and options are, as of nanoc 3.2, no
    # longer used, and will simply be ignored when passed to {#run}.
    #
    # @overload run
    #   @return [void]
    def run(*args)
      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Compile reps
      load
      @site.freeze
      dependency_tracker.start
      compile_reps(reps)
      dependency_tracker.stop
      store
    ensure
      # Cleanup
      FileUtils.rm_rf(Nanoc3::Filter::TMP_BINARY_ITEMS_DIR)
    end

    # @group Private instance methods

    # Load the helper data that is used for compiling the site.
    #
    # @api private
    #
    # @return [void]
    def load
      return if @loaded

      # Load site if necessary
      @site.load

      # Preprocess
      load_rules
      preprocess
      site.setup_child_parent_links
      build_reps
      route_reps

      # Load auxiliary stores
      stores.each { |s| s.load }

      # Determine which reps need to be recompiled
      dependency_tracker.propagate_outdatedness
      forget_dependencies_if_outdated(items)

      @loaded = true
    end

    # Store the modified helper data used for compiling the site.
    #
    # @api private
    #
    # @return [void]
    def store
      stores.each { |s| s.store }
    end

    # Returns the dependency tracker for this site, creating it first if it
    # does not yet exist.
    #
    # @api private
    #
    # @return [Nanoc3::DependencyTracker] The dependency tracker for this site
    def dependency_tracker
      @dependency_tracker ||= begin
        dt = Nanoc3::DependencyTracker.new(@site.items + @site.layouts)
        dt.compiler = self
        dt
      end
    end

    # Finds the first matching compilation rule for the given item
    # representation.
    #
    # @api private
    #
    # @param [Nanoc3::ItemRep] rep The item rep for which to fetch the rule
    #
    # @return [Nanoc3::Rule, nil] The compilation rule for the given item rep,
    #   or nil if no rules have been found
    def compilation_rule_for(rep)
      @item_compilation_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Finds the first matching routing rule for the given item representation.
    #
    # @api private
    #
    # @param [Nanoc3::ItemRep] rep The item rep for which to fetch the rule
    #
    # @return [Nanoc3::Rule, nil] The routing rule for the given item rep, or
    #   nil if no rules have been found
    def routing_rule_for(rep)
      @item_routing_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Returns the list of routing rules that can be applied to the given item
    # representation. For each snapshot, the first matching rule will be
    # returned. The result is a hash containing the corresponding rule for
    # each snapshot.
    #
    # @api private
    #
    # @return [Hash<Symbol, Nanoc3::Rule>] The routing rules for the given rep
    def routing_rules_for(rep)
      rules = {}
      @item_routing_rules.each do |rule|
        next if !rule.applicable_to?(rep.item)
        next if rule.rep_name != rep.name
        next if rules.has_key?(rule.snapshot_name)

        rules[rule.snapshot_name] = rule
      end
      rules
    end

    # Finds the filter name and arguments to use for the given layout.
    #
    # @api private
    #
    # @param [Nanoc3::Layout] layout The layout for which to fetch the filter.
    #
    # @return [Array, nil] A tuple containing the filter name and the filter 
    #   arguments for the given layout.
    def filter_for_layout(layout)
      @layout_filter_mapping.each_pair do |layout_identifier, filter_name_and_args|
        return filter_name_and_args if layout.identifier =~ layout_identifier
      end
      nil
    end

    # @api private
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def outdated?(obj)
      outdatedness_checker.outdated?(obj)
    end

    # Returns the reason why the given object is outdated.
    #
    # @see Nanoc3::OutdatednessChecker#outdatedness_reason_for
    #
    # @api private
    def outdatedness_reason_for(obj)
      outdatedness_checker.outdatedness_reason_for(obj)
    end

    # Checks whether the given item representation needs to be recompiled.
    # This is the case if the representation itself has changed, or when any
    # of the dependent items need to be recompiled.
    #
    # @api private
    #
    # @return [Boolean] true if the given item representation needs to be
    #   recompiled, false otherwise.
    def needs_recompiling?(rep)
      outdated?(rep) || dependency_tracker.outdated_due_to_dependencies?(rep.item)
    end

    # Returns the Nanoc3::CompilerDSL that should be used for this site.
    #
    # @api private
    def dsl
      @dsl ||= Nanoc3::CompilerDSL.new(self)
    end

    # Loads this site’s rules.
    #
    # @api private
    def load_rules
      # Find rules file
      rules_filename = [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].find { |f| File.file?(f) }
      raise Nanoc3::Errors::NoRulesFileFound.new if rules_filename.nil?

      # Get rule data
      @rules = File.read(rules_filename)

      # Load DSL
      dsl.instance_eval(@rules, "./#{rules_filename}")
    end

    # Runs the preprocessor.
    #
    # @api private
    def preprocess
      preprocessor_context.instance_eval(&preprocessor) if preprocessor
    end

    # Returns all objects managed by the site (items, layouts, code snippets,
    # site configuration and the rules).
    #
    # @api private
    def objects
      # FIXME remove reference to rules
      site.items + site.layouts + site.code_snippets + [ site.config, self.rules_with_reference ]
    end

    # Returns the rules along with an unique reference (`:rules`) so that the
    # outdatedness checker can use them.
    #
    # @api private
    def rules_with_reference
      rules = @rules
      @rules_pseudo ||= begin
        pseudo = Object.new
        pseudo.instance_eval { @data = rules }
        def pseudo.reference ; :rules ; end
        def pseudo.data ; @data.inspect ; end
        pseudo
      end
    end

    # Creates the representations of all items as defined by the compilation
    # rules.
    #
    # @api private
    def build_reps
      @site.items.each do |item|
        # Find matching rules
        matching_rules = item_compilation_rules.select { |r| r.applicable_to?(item) }
        raise Nanoc3::Errors::NoMatchingCompilationRuleFound.new(item) if matching_rules.empty?

        # Create reps
        rep_names = matching_rules.map { |r| r.rep_name }.uniq
        rep_names.each do |rep_name|
          item.reps << ItemRep.new(item, rep_name)
        end
      end
    end

    # Determines the paths of all item representations.
    #
    # @api private
    def route_reps
      reps = @site.items.map { |i| i.reps }.flatten
      reps.each do |rep|
        # Find matching rules
        rules = routing_rules_for(rep)
        raise Nanoc3::Errors::NoMatchingRoutingRuleFound.new(rep) if rules[:last].nil?

        rules.each_pair do |snapshot, rule|
          # Get basic path by applying matching rule
          basic_path = rule.apply_to(rep, :compiler => self)
          next if basic_path.nil?
          if basic_path !~ %r{^/}
            raise RuntimeError, "The path returned for the #{rep.inspect} item representation, “#{basic_path}”, does not start with a slash. Please ensure that all routing rules return a path that starts with a slash.".make_compatible_with_env
          end

          # Get raw path by prepending output directory
          rep.raw_paths[snapshot] = @site.config[:output_dir] + basic_path

          # Get normal path by stripping index filename
          rep.paths[snapshot] = basic_path
          @site.config[:index_filenames].each do |index_filename|
            if rep.paths[snapshot][-index_filename.length..-1] == index_filename
              # Strip and stop
              rep.paths[snapshot] = rep.paths[snapshot][0..-index_filename.length-1]
              break
            end
          end
        end
      end
    end

    # @param [Nanoc3::ItemRep] rep The item representation for which the
    #   assigns should be fetched
    #
    # @return [Hash] The assigns that should be used in the next filter/layout
    #   operation
    #
    # @api private
    def assigns_for(rep)
      if rep.binary?
        content_or_filename_assigns = { :filename => rep.temporary_filenames[:last] }
      else
        content_or_filename_assigns = { :content => rep.content[:last] }
      end

      content_or_filename_assigns.merge({
        :item       => rep.item,
        :item_rep   => rep,
        :items      => site.items,
        :layouts    => site.layouts,
        :config     => site.config,
        :site       => site
      })
    end

  private

    def items
      @items ||= @site.items
    end

    def reps
      @reps ||= items.map { |i| i.reps }.flatten
    end

    # Compiles the given representations.
    #
    # @param [Array] reps The item representations to compile.
    #
    # @return [void]
    def compile_reps(reps)
      require 'set'

      # Partition in outdated and non-outdated
      outdated_reps = Set.new
      skipped_reps  = Set.new
      reps.each do |rep|
        target = needs_recompiling?(rep) ? outdated_reps : skipped_reps
        target.add(rep)
      end

      # Build graph for outdated reps
      content_dependency_graph = Nanoc3::DirectedGraph.new(outdated_reps)

      # Listen to processing start/stop
      Nanoc3::NotificationCenter.on(:processing_started, self) { |obj| @stack.push(obj) }
      Nanoc3::NotificationCenter.on(:processing_ended,   self) { |obj| @stack.pop       }

      # Attempt to compile all active reps
      loop do
        # Find rep to compile
        break if content_dependency_graph.roots.empty?
        rep = content_dependency_graph.roots.each { |e| break e }
        @stack = []

        begin
          compile_rep(rep)
          content_dependency_graph.delete_vertex(rep)
        rescue Nanoc3::Errors::UnmetDependency => e
          content_dependency_graph.add_edge(e.rep, rep)
          unless content_dependency_graph.vertices.include?(e.rep)
            skipped_reps.delete(e.rep)
            content_dependency_graph.add_vertex(e.rep)
          end
        end
      end

      # Check whether everything was compiled
      if !content_dependency_graph.vertices.empty?
        raise Nanoc3::Errors::RecursiveCompilation.new(content_dependency_graph.vertices)
      end
    ensure
      Nanoc3::NotificationCenter.remove(:processing_started, self)
      Nanoc3::NotificationCenter.remove(:processing_ended,   self)
    end

    # Compiles the given item representation.
    #
    # This method should not be called directly; please use
    # {Nanoc3::Compiler#run} instead, and pass this item representation's item
    # as its first argument.
    #
    # @param [Nanoc3::ItemRep] rep The rep that is to be compiled
    #
    # @return [void]
    def compile_rep(rep)
      Nanoc3::NotificationCenter.post(:compilation_started, rep)
      Nanoc3::NotificationCenter.post(:processing_started,  rep)
      Nanoc3::NotificationCenter.post(:visit_started,       rep.item)

      if !needs_recompiling?(rep) && compiled_content_cache[rep]
        Nanoc3::NotificationCenter.post(:cached_content_used, rep)
        rep.content = compiled_content_cache[rep]
      else
        rep.snapshot(:raw)
        rep.snapshot(:pre, :final => false)
        compilation_rule_for(rep).apply_to(rep, :compiler => self)
        rep.snapshot(:post) if rep.has_snapshot?(:post)
        rep.snapshot(:last)
      end

      rep.compiled = true
      compiled_content_cache[rep] = rep.content
    rescue => e
      rep.forget_progress
      Nanoc3::NotificationCenter.post(:compilation_failed, rep)
      raise e
    ensure
      Nanoc3::NotificationCenter.post(:visit_ended,       rep.item)
      Nanoc3::NotificationCenter.post(:processing_ended,  rep)
      Nanoc3::NotificationCenter.post(:compilation_ended, rep)
    end

    # Clears the list of dependencies for items that will be recompiled.
    #
    # @param [Array<Nanoc3::Item>] items The list of items for which to forget
    #   the dependencies
    #
    # @return [void]
    def forget_dependencies_if_outdated(items)
      items.each do |i|
        if i.reps.any? { |r| needs_recompiling?(r) }
          dependency_tracker.forget_dependencies_for(i)
        end
      end
    end

    # Returns a preprocessor context, creating one if none exists yet.
    def preprocessor_context
      @preprocessor_context ||= Nanoc3::Context.new({
        :site    => @site,
        :config  => @site.config,
        :items   => @site.items,
        :layouts => @site.layouts
      })
    end

    # @return [CompiledContentCache] The compiled content cache
    def compiled_content_cache
      @compiled_content_cache ||= Nanoc3::CompiledContentCache.new
    end

    # @return [ChecksumStore] The checksum store
    def checksum_store
      @checksum_store ||= Nanoc3::ChecksumStore.new(:site => @site)
    end

    # @return [Nanoc3::OutdatednessChecker] The outdatedness checker
    def outdatedness_checker
      @outdatedness_checker ||= Nanoc3::OutdatednessChecker.new(:site => @site, :checksum_store => checksum_store)
    end

    # Returns all stores that can load/store data that can be used for
    # compilation.
    def stores
      [ compiled_content_cache, checksum_store, dependency_tracker ]
    end

  end

end
