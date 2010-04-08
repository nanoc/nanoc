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
    # its dependencies. Pass `nil` if the entire site should be compiled.
    #
    # @option params [Boolean] :force (false) true if the rep should be
    # compiled even if it is not outdated, false if not
    #
    # @return [void]
    def run(item=nil, params={})
      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Load dependencies
      dependency_tracker.load_graph

      # Get items and reps to compile
      if item
        items = [ item ] + dependency_tracker.successors_of(item)
        items.uniq!
      else
        items = @site.items
      end
      reps = items.map { |i| i.reps }.flatten

      # Prepare dependencies
      if params.has_key?(:force) && params[:force]
        reps.each { |r| r.force_outdated = true }
      else
        dependency_tracker.propagate_outdatedness
      end
      forget_dependencies_if_outdated(items)

      # Compile reps
      dependency_tracker.start
      compile_reps(reps)
      dependency_tracker.stop

      # Cleanup
      FileUtils.rm_rf(Nanoc3::Filter::TMP_BINARY_ITEMS_DIR)

      # Store checksums
      # FIXME not the right place
      @site.store_checksums

      # Store dependencies
      dependency_tracker.store_graph
    end

    # Finds the first matching compilation rule for the given item
    # representation.
    #
    # @param [Nanoc3::ItemRep] rep The item rep for which to fetch the rule
    #
    # @return [Nanoc3::Rule, nil] The compilation rule for the given item rep,
    # or nil if no rules have been found
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
    # nil if no rules have been found
    def routing_rule_for(rep)
      @item_routing_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Finds the filter name and arguments to use for the given layout.
    #
    # @param [Nanoc3::Layout] layout The layout for which to fetch the filter.
    #
    # @return [Array, nil] A tuple containing the filter name and the filter 
    # arguments for the given layout.
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
      active_reps, skipped_reps = reps.partition { |rep| rep.outdated? || rep.item.outdated_due_to_dependencies? }
      inactive_reps = []
      compiled_reps = []

      load_cached_compiled_content

      # Repeat as long as something is successfully compiled...
      changed = true
      until !changed
        changed = false

        # Attempt to compile all active reps
        until active_reps.empty?
          @stack.clear
          begin
            rep = active_reps.shift
            puts "*** Attempting to compile #{rep.inspect}" if $DEBUG

            @stack.push(rep)
            compile_rep(rep)
          rescue Nanoc3::Errors::UnmetDependency => e
            puts "*** Attempt failed due to unmet dependency on #{e.rep.inspect}" if $DEBUG

            # Reinitialize rep
            rep.forget_progress

            # Save rep to compile it later
            inactive_reps << rep

            # Add dependency to list of items to compile
            unless active_reps.include?(e.rep) || inactive_reps.include?(e.rep)
              changed = true
              skipped_reps.delete(e.rep)
              inactive_reps.unshift(e.rep)
            end
          else
            puts "*** Attempt succeeded" if $DEBUG

            changed = true
            compiled_reps << rep
          end
          puts if $DEBUG
        end

        # Retry
        if inactive_reps.empty?
          puts "*** Nothing left to compile!" if $DEBUG
          break
        else
          puts "*** No active reps left; activating all (#{inactive_reps.size}) inactive reps" if $DEBUG
          puts if $DEBUG
          active_reps   = inactive_reps
          inactive_reps = []
        end
      end

      store_cached_compiled_content

      # Notify skipped reps
      skipped_reps.each do |rep|
        Nanoc3::NotificationCenter.post(:compilation_started, rep)
        Nanoc3::NotificationCenter.post(:compilation_ended,   rep)
      end

      # Raise error if some active but non-compileable reps are left
      if !active_reps.empty?
        raise Nanoc3::Errors::RecursiveCompilation.new(active_reps)
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
      # Start
      Nanoc3::NotificationCenter.post(:compilation_started, rep)
      Nanoc3::NotificationCenter.post(:visit_started,       rep.item)

      if !rep.outdated? && !rep.item.outdated_due_to_dependencies && get_cached_compiled_content_for(rep)
        # Load content from cache if possible
        puts "Using cached compiled content for #{rep.inspect} instead of recompiling" if $DEBUG
        cached_compiled_content = get_cached_compiled_content_for(rep)
        # FIXME don’t use instance_eval
        rep.instance_eval { @content = cached_compiled_content }
      else
        # Apply matching rule
        compilation_rule_for(rep).apply_to(rep)
      end
      rep.compiled = true

      # Write if rep is routed
      # FIXME don’t use instance_eval
      set_cached_compiled_content_for(rep, rep.instance_eval { @content })
      rep.write unless rep.raw_path.nil?
    ensure
      # Stop
      Nanoc3::NotificationCenter.post(:visit_ended,       rep.item)
      Nanoc3::NotificationCenter.post(:compilation_ended, rep)
    end

    # Loads cached compiled content into memory.
    def load_cached_compiled_content
      require 'pstore'

      if !File.file?(COMPILED_CONTENT_CACHE_FILENAME)
        @cached_compiled_content = {}
      else
        store = PStore.new(COMPILED_CONTENT_CACHE_FILENAME)
        store.transaction do
          @cached_compiled_content = store[:compiled_content]
        end
      end
    end

    # Stores cached compiled content back to disk.
    def store_cached_compiled_content
      require 'pstore'

      FileUtils.mkdir_p(File.dirname(COMPILED_CONTENT_CACHE_FILENAME))
      store = PStore.new(COMPILED_CONTENT_CACHE_FILENAME)
      store.transaction do
        store[:compiled_content] = @cached_compiled_content
      end
    end

    # Gets the compiled content for the given item representation
    def get_cached_compiled_content_for(rep)
      @cached_compiled_content ||= {}
      @cached_compiled_content[rep.item.identifier] ||= {}
      @cached_compiled_content[rep.item.identifier][rep.name] || {}
    end

    # Sets the compiled content for the given item representation
    def set_cached_compiled_content_for(rep, content)
      @cached_compiled_content ||= {}
      @cached_compiled_content[rep.item.identifier] ||= {}
      @cached_compiled_content[rep.item.identifier][rep.name] = content
    end

    # Returns the dependency tracker for this site, creating it first if it
    # does not yet exist.
    # 
    # @return [Nanoc3::DependencyTracker] The dependency tracker for this site
    def dependency_tracker
      @dependency_tracker ||= Nanoc3::DependencyTracker.new(@site.items)
    end

    # Clears the list of dependencies for items that will be recompiled.
    #
    # @param [Array<Nanoc3::Item>] items The list of items for which to forget
    # the dependencies
    #
    # @return [void]
    def forget_dependencies_if_outdated(items)
      items.each do |i|
        if i.outdated? || i.outdated_due_to_dependencies?
          dependency_tracker.forget_dependencies_for(i)
        end
      end
    end

  end

end
