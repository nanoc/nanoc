# encoding: utf-8

module Nanoc3

  # Nanoc3::Compiler is responsible for compiling a site's item
  # representations.
  class Compiler

    # The compilation stack. When the compiler begins compiling a rep or a
    # layout, it will be placed on the stack; when it is done compiling the
    # rep or layout, it will be removed from the stack.
    attr_reader :stack

    # The list of compilation rules that will be used to compile items. This
    # array will be filled by Nanoc3::Site#load_data.
    attr_reader :item_compilation_rules

    # The list of routing rules that will be used to give all items a path.
    # This array will be filled by Nanoc3::Site#load_data.
    attr_reader :item_routing_rules

    # The hash containing layout-to-filter mapping rules.
    attr_reader :layout_filter_mapping

    # @param [Nanoc3::Site] site The site this compiler belongs to.
    def initialize(site)
      @site = site

      @stack = []

      @item_compilation_rules  = []
      @item_routing_rules      = []
      @layout_filter_mapping   = {}
    end

    # Compiles (part of) the site and writes out the compiled item
    # representations.
    #
    # @param [Nanoc3::Item] item The item that should be compiled, along with
    #   its dependencies. Pass +nil+ if the entire site should be compiled.
    #
    # @option params [Boolean] :force (false) true if the rep should be
    #   compiled even if it is not outdated, false if not.
    def run(item=nil, params={})
      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Load dependencies
      dependency_tracker.load_graph
      print_dependency_graph if $DEBUG

      # Get items and reps to compile
      if item
        items = [ item ] + dependency_tracker.all_inverse_dependencies_for(item)
        items.uniq!
      else
        items = @site.items
      end
      reps = items.map { |i| i.reps }.flatten

      # Prepare dependencies
      mark_outdated_items(reps, params.has_key?(:force) && params[:force])
      forget_dependencies_if_outdated(items)

      # Compile reps
      dependency_tracker.start
      compile_reps(reps)
      dependency_tracker.stop

      # Store dependencies
      dependency_tracker.store_graph
    end

    # @param [Nanoc3::ItemRep] rep The item representation for which to fetch
    #   the first matching compilation rule.
    #
    # @return [Nanoc3::Rule] The first matching compilation rule for the given rep.
    def compilation_rule_for(rep)
      @item_compilation_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # @param [Nanoc3::ItemRep] rep The item representation for which to fetch
    #   the first matching routing rule.
    #
    # @return [Nanoc3::Rule] The first matching routing rule for the given rep.
    def routing_rule_for(rep)
      @item_routing_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

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
    def compile_reps(reps)
      active_reps, skipped_reps = reps.partition { |rep| rep.outdated? || rep.item.dependencies_outdated? }
      inactive_reps = []
      compiled_reps = []

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
        puts "*** No active reps left; activating all (#{inactive_reps.size}) inactive reps" if $DEBUG
        puts if $DEBUG
        active_reps   = inactive_reps
        inactive_reps = []
      end

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
    # Nanoc3::Compiler#run instead, and pass this item representation's item
    # as its first argument.
    #
    # @param [Nanoc3::ItemRep] rep The rep that is to be compiled.
    def compile_rep(rep)
      # Start
      Nanoc3::NotificationCenter.post(:compilation_started, rep)
      Nanoc3::NotificationCenter.post(:visit_started,       rep.item)

      # Apply matching rule
      compilation_rule_for(rep).apply_to(rep)
      rep.compiled = true

      # Write if rep is routed
      rep.write unless rep.raw_path.nil?

      # Stop
      Nanoc3::NotificationCenter.post(:visit_ended,       rep.item)
      Nanoc3::NotificationCenter.post(:compilation_ended, rep)
    end

    # @return [Nanoc3::DependencyTracker] the dependency tracker for this site.
    def dependency_tracker
      @dependency_tracker ||= Nanoc3::DependencyTracker.new(@site.items)
    end

    # Marks the necessary items as outdated.
    #
    # FIXME this method needs a different signature, fast
    def mark_outdated_items(reps, force)
      if force
        reps.each { |r| r.force_outdated = true }
      else
        dependency_tracker.mark_outdated_items
      end
    end

    # Clears the list of dependencies for items that will be recompiled.
    def forget_dependencies_if_outdated(items)
      items.each do |i|
        if i.outdated? || i.dependencies_outdated?
          dependency_tracker.forget_dependencies_for(i)
        end
      end
    end

    # Prints the dependency graph.
    def print_dependency_graph
      graph = dependency_tracker.instance_eval { @graph }
      puts "DEPENDENCY GRAPH:"
      graph.each_pair do |key, values|
        puts "#{key.inspect} depends on:"
        values.each do |value|
          puts "    #{value.inspect}"
        end
        puts "    (nothing!)" if values.empty?
        puts
      end
    end

  end

end
