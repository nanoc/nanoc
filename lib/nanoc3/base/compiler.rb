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

    # Creates a new compiler for the given site.
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
    # +items+:: The items that should be compiled, along with their
    #           dependencies. Pass +nil+ if the entire site should be
    #           compiled.
    #
    # This method also accepts a few optional parameters:
    #
    # +:force+:: true if the rep should be compiled even if it is not
    #            outdated, false if not. Defaults to false.
    def run(items=nil, params={})
      # Create output directory if necessary
      FileUtils.mkdir_p(@site.config[:output_dir])

      # Get items and reps to compile
      items ||= @site.items
      reps = items.map { |i| i.reps }.flatten

      # Load dependencies
      dependency_tracker.load_graph

      # Prepare dependencies
      mark_outdated_items(reps, params.has_key?(:force) && params[:force])
      forget_dependencies_if_outdated(items)

      # Debug
      print_dependency_graph if $DEBUG

      # Compile reps
      dependency_tracker.start
      compile_reps(reps)
      dependency_tracker.stop

      # Store dependencies
      dependency_tracker.store_graph
    end

    # Returns the first matching compilation rule for the given rep.
    def compilation_rule_for(rep)
      @item_compilation_rules.find do |rule|
        rule.applicable_to?(rep.item) && rule.rep_name == rep.name
      end
    end

    # Returns the first matching routing rule for the given rep.
    def routing_rule_for(rep)
      @item_routing_rules.find do |rule|
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

  private

    # Compiles all item representations in the site.
    def compile_reps(reps)
      active_reps     = reps.dup
      inactive_reps   = []
      compiled_reps   = []

      # Repeat as long as something is successfully compiled...
      changed = true
      until !changed
        changed = false

        # Attempt to compile all active reps
        until active_reps.empty?
          @stack.clear
          begin
            rep = active_reps.shift
            @stack.push(rep)
            compile_rep(rep)
          rescue Nanoc3::Errors::UnmetDependency => e
            inactive_reps << rep
          else
            changed = true
            compiled_reps << rep
          end
        end

        # Retry
        active_reps   = inactive_reps
        inactive_reps = []
      end

      # Raise error if some active but non-compileable reps are left
      if !active_reps.empty?
        # FIXME as a workaround, check whether the reps param is complete
        raise Nanoc3::Errors::RecursiveCompilation.new(active_reps)
      end
    end

    # Compiles the given item representation.
    #
    # This method should not be called directly; please use
    # Nanoc3::Compiler#run instead, and pass this item representation's item as
    # its first argument.
    #
    # +rep+:: The rep that is to be compiled.
    def compile_rep(rep)
      # Skip unless outdated
      if !rep.outdated? && !rep.item.dependencies_outdated?
        Nanoc3::NotificationCenter.post(:compilation_started, rep)
        Nanoc3::NotificationCenter.post(:visit_started,       rep.item)
        Nanoc3::NotificationCenter.post(:visit_ended,         rep.item)
        Nanoc3::NotificationCenter.post(:compilation_ended,   rep)
        return
      end

      # Start
      Nanoc3::NotificationCenter.post(:compilation_started, rep)
      Nanoc3::NotificationCenter.post(:visit_started,       rep.item)

      # Apply matching rule
      compilation_rule_for(rep).apply_to(rep)
      rep.compiled = true

      # Stop
      Nanoc3::NotificationCenter.post(:visit_ended,       rep.item)
      Nanoc3::NotificationCenter.post(:compilation_ended, rep)
    end

    # Returns the dependency tracker for this site.
    def dependency_tracker
      @dependency_tracker ||= Nanoc3::DependencyTracker.new(@site.items)
    end

    # Marks the necessary items as outdated.
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
