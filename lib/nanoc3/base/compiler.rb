# encoding: utf-8

module Nanoc3

  # Responsible for compiling a site’s item representations.
  class Compiler

    # The name of the file where cached compiled content will be stored
    COMPILED_CONTENT_CACHE_FILENAME = 'tmp/compiled_content'

    # The compilation stack. When the compiler begins compiling a rep or a
    # layout, it will be placed on the stack; when it is done compiling the
    # rep or layout, it will be removed from the stack.
    #
    # @return [Array] The compilation stack
    attr_reader :stack

    # The list of compilation rules that will be used to compile items. This
    # array will be filled by {Nanoc3::Site#load_data}.
    #
    # @return [Array<Nanoc3::Rule>] The list of item compilation rules
    attr_reader :item_compilation_rules

    # The list of routing rules that will be used to give all items a path.
    # This array will be filled by {Nanoc3::Site#load_data}.
    #
    # @return [Array<Nanoc3::Rule>] The list of item routing rules
    attr_reader :item_routing_rules

    # The hash containing layout-to-filter mapping rules. This hash is
    # ordered: iterating over the hash will happen in insertion order.
    #
    # @return [Hash] The layout-to-filter mapping rules
    attr_reader :layout_filter_mapping

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

    # Compiles (part of) the site and writes out the compiled item
    # representations.
    #
    # @param [Nanoc3::Item] item The item that should be compiled, along with
    #   its dependencies. Pass `nil` if the entire site should be compiled.
    #
    # @option params [Boolean] :force (false) true if the rep should be
    #   compiled even if it is not outdated, false if not
    #
    # @return [void]
    def run(item=nil, params={})
      # Parse params
      params[:force] = false if !params.has_key?(:force)

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Load necessary data
      compiled_content_cache = CompiledContentCache.new(COMPILED_CONTENT_CACHE_FILENAME)
      compiled_content_cache.load
      dependency_tracker.load_graph

      # Get items and reps to compile
      items = item ? ([ item ] + dependency_tracker.successors_of(item)).uniq : @site.items
      reps = items.map { |i| i.reps }.flatten

      # Determine which reps need to be recompiled
      reps.each { |r| r.force_outdated = true } if params[:force]
      dependency_tracker.propagate_outdatedness
      forget_dependencies_if_outdated(items)

      # Compile reps
      dependency_tracker.start
      compile_reps(reps)
      dependency_tracker.stop

      # Store necessary data
      compiled_content_cache.store
      @site.store_checksums
      dependency_tracker.store_graph
    ensure
      # Cleanup
      FileUtils.rm_rf(Nanoc3::Filter::TMP_BINARY_ITEMS_DIR)
    end

    # Returns the dependency tracker for this site, creating it first if it
    # does not yet exist.
    # 
    # @return [Nanoc3::DependencyTracker] The dependency tracker for this site
    def dependency_tracker
      @dependency_tracker ||= Nanoc3::DependencyTracker.new(@site.items)
    end

    # Finds the first matching compilation rule for the given item
    # representation.
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

  private

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
        target = (rep.outdated? || rep.item.outdated_due_to_dependencies?) ? outdated_reps : skipped_reps
        target.add(rep)
      end

      # Build graph for outdated reps
      content_dependency_graph = Nanoc3::DirectedGraph.new(outdated_reps)

      # Attempt to compile all active reps
      loop do
        # Find rep to compile
        break if content_dependency_graph.roots.empty?
        rep = content_dependency_graph.roots.each { |e| break e }
        @stack = [ rep ]

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

      # Notify skipped reps
      skipped_reps.each do |rep|
        Nanoc3::NotificationCenter.post(:compilation_started, rep)
        Nanoc3::NotificationCenter.post(:compilation_ended,   rep)
      end
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
      Nanoc3::NotificationCenter.post(:visit_started,       rep.item)

      if !rep.outdated? && !rep.item.outdated_due_to_dependencies && compiled_content_cache[rep]
        Nanoc3::NotificationCenter.post(:cached_content_used, rep)
        rep.content = compiled_content_cache[rep]
      else
        rep.snapshot(:raw)
        rep.snapshot(:pre, :final => false)
        compilation_rule_for(rep).apply_to(rep)
        rep.snapshot(:post) if rep.compiled_content(:snapshot => :post, :force => true)
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
        if i.outdated? || i.outdated_due_to_dependencies?
          dependency_tracker.forget_dependencies_for(i)
        end
      end
    end

    # Returns the cache used for storing compiled content.
    #
    # @return [CompiledContentCache] The compiled content cache
    def compiled_content_cache
      @compiled_content_cache ||= begin
        cache = CompiledContentCache.new(COMPILED_CONTENT_CACHE_FILENAME)
        cache.load
        cache
      end
    end

    # Represents a cache than can be used to store already compiled content,
    # to prevent it from being needlessly recompiled.
    #
    # This class is intended for internal use only. Do not rely on its
    # presence; future versions of nanoc, even in the 3.x branch, may no
    # longer contain this class.
    class CompiledContentCache

      # @return [String] The filename where the cache will be loaded from
      #   and stored to
      attr_reader :filename

      # Creates a new cache for the given filename.
      #
      # @param [String] filename The filename where the cache will be loaded
      #   from and stored to
      def initialize(filename)
        require 'pstore'

        @filename = filename
      end

      # Loads the cache from the filesystem into memory.
      #
      # @return [void]
      def load
        cache = nil
        return if !File.file?(filename)
        pstore.transaction { cache = pstore[:compiled_content] }
      end

      # Stores the content of the (probably modified) in-memory cache to the
      #   filesystem.
      #
      # @return [void]
      def store
        FileUtils.mkdir_p(File.dirname(filename))
        pstore.transaction { pstore[:compiled_content] = cache }
      end

      # Returns the cached compiled content for the given item
      # representation. This cached compiled content is a hash where the keys
      # are the snapshot names and the values the compiled content at the
      # given snapshot.
      #
      # @param [Nanoc3::ItemRep] rep The item rep to fetch the content for
      #
      # @return [Hash<Symbol,String>] A hash containing the cached compiled
      #   content for the given item representation
      def [](rep)
        item_cache = cache[rep.item.identifier] || {}
        item_cache[rep.name]
      end

      # Sets the compiled content for the given representation.
      #
      # @param [Nanoc3::ItemRep] rep The item representation for which to set
      #   the compiled content
      #
      # @param [Hash<Symbol,String>] content A hash containing the compiled
      #   content of the given representation
      #
      # @return [void]
      def []=(rep, content)
        cache[rep.item.identifier] ||= {}
        cache[rep.item.identifier][rep.name] = content
      end

    private

      def cache
        @cache ||= {}
      end

      def pstore
        require 'pstore'
        @store ||= PStore.new(@filename)
      end

    end

  end

end
