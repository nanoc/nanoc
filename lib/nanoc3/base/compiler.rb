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

    # Compiles the site and writes out the compiled item representations.
    #
    # @overload run(params={})
    #   @option params [Boolean] :force (false) true if all representations
    #     should be compiled even if they are not outdated, false if not
    #   @return [void]
    def run(*args)
      # Parse arguments
      params = {}
      if args.size >= 1 && args[0].is_a?(Hash)
        params = args[0]
      elsif args.size >= 2 && args[1].is_a?(Hash)
        params = args[1]
      end
      params[:force] = false if !params.has_key?(:force)

      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Load necessary data
      compiled_content_cache.load
      dependency_tracker.load_graph

      # Get items and reps to compile
      items = @site.items
      reps  = items.map { |i| i.reps }.flatten

      # Determine which reps need to be recompiled
      reps.each { |r| r.force_outdated = true } if params[:force]
      determine_outdatedness(reps)
      dependency_tracker.propagate_outdatedness
      forget_dependencies_if_outdated(items)

      # Compile reps
      dependency_tracker.start
      compile_reps(reps)
      dependency_tracker.stop

      # Store necessary data
      compiled_content_cache.store
      checksum_store.store
      dependency_tracker.store_graph
    ensure
      # Cleanup
      FileUtils.rm_rf(Nanoc3::Filter::TMP_BINARY_ITEMS_DIR)
    end

    # Returns the dependency tracker for this site, creating it first if it
    # does not yet exist.
    #
    # @private
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
    # @private
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
    # @private
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
    # @private
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
    # @private
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

    # @private
    #
    # @return [Boolean] true if the object is outdated, false otherwise
    def outdated?(obj)
      case obj.type
        when :item_rep
          !!@outdatedness_reasons[obj] || obj.force_outdated
        when :item
          obj.reps.any? { |rep| outdated?(rep) }
        when :layout
          checksum_store.object_modified?(obj)
        else
          raise RuntimeError, "do not know how to check outdatedness of #{obj.inspect}"
      end
    end

    # TODO document
    #
    # @private
    def outdatedness_reason_for(rep)
      @outdatedness_reasons[rep]
    end

  private

    # The descriptive strings for each outdatedness reason.
    OUTDATEDNESS_REASON_DESCRIPTIONS = {
      :not_enough_data => 'Not enough data is present to correctly determine whether the item is outdated.',
      :forced => 'All items are recompiled because of a `--force` flag given to the compilation command.',
      :not_written => 'This item representation has not yet been written to the output directory (but it does have a path).',
      :source_modified => 'The source file of this item has been modified since the last time this item representation was compiled.',
      :layouts_outdated => 'The source of one or more layouts has been modified since the last time this item representation was compiled.',
      :code_outdated => 'The code snippets in the `lib/` directory have been modified since the last time this item representation was compiled.',
      :config_outdated => 'The site configuration has been modified since the last time this item representation was compiled.',
      :rules_outdated => 'The rules file has been modified since the last time this item representation was compiled.',
    }

    # Determines whether the given representations are outdated or not. For
    # outdated representations, the outdatedness reason will be set.
    #
    # The outdatedness reason is a hash with a `:type` key, containing the
    # reason why the item is outdated in the form of a symbol, and a
    # `:description` key, containing a descriptive string that can be printed
    # if necessary.
    #
    # @return [void]
    def determine_outdatedness(reps)
      # TODO outdatedness reasons should be objects with descriptions
      # TODO should item reps know their outdatedness?

      @outdatedness_reasons ||= {}
      reps.each do |rep|
        # Get reason symbol
        reason = lambda do
          # Outdated if we’re compiling with --force
          return :forced if rep.force_outdated

          # Outdated if checksums are missing or different
          return :not_enough_data if !checksum_store.checksums_available?(rep.item)
          return :source_modified if !checksum_store.checksums_identical?(rep.item)

          # Outdated if compiled file doesn't exist (yet)
          return :not_written if rep.raw_path && !File.file?(rep.raw_path)

          # Outdated if code snippets outdated
          return :code_outdated if @site.code_snippets.any? { |cs| checksum_store.object_modified?(cs) }

          # Outdated if configuration outdated
          return :config_outdated if checksum_store.object_modified?(@site.config_with_reference)

          # Outdated if rules outdated
          return :rules_outdated  if checksum_store.object_modified?(@site.rules_with_reference)

          return nil
        end[]

        # Build reason symbol and description
        next if reason.nil?
        @outdatedness_reasons[rep] = {
          :type        => reason,
          :description => OUTDATEDNESS_REASON_DESCRIPTIONS[reason]
        }
      end
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
        target = (outdated?(rep) || rep.item.outdated_due_to_dependencies?) ? outdated_reps : skipped_reps
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

      if !outdated?(rep) && !rep.item.outdated_due_to_dependencies && compiled_content_cache[rep]
        Nanoc3::NotificationCenter.post(:cached_content_used, rep)
        rep.content = compiled_content_cache[rep]
      else
        rep.snapshot(:raw)
        rep.snapshot(:pre, :final => false)
        compilation_rule_for(rep).apply_to(rep)
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
        if i.reps.any? { |r| outdated?(r) } || i.outdated_due_to_dependencies?
          dependency_tracker.forget_dependencies_for(i)
        end
      end
    end

    # @return [CompiledContentCache] The compiled content cache
    def compiled_content_cache
      @compiled_content_cache ||= Nanoc3::CompiledContentCache.new
    end

    # @return [ChecksumStore] The checksum store
    def checksum_store
      @checksum_store ||= Nanoc3::ChecksumStore.new
    end

  end

end
