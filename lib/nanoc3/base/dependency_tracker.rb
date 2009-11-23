# encoding: utf-8

require 'pstore'

module Nanoc3

  # Nanoc3::DependencyTracker is responsible for remembering dependencies
  # between items. It is used to speed up compilation by only letting an item
  # be recompiled when it is outdated or any of its dependencies (or
  # dependencies' dependencies, etc) is outdated.
  #
  # The dependencies tracked by the dependency tracker are not dependencies
  # based on an item's content. When one item uses an attribute of another
  # item, then this is also treated as a dependency. While dependencies based
  # on an item's content (handled in Nanoc3::Compiler) cannot be mutually
  # recursive, the more general dependencies in Nanoc3::DependencyTracker can
  # (e.g. item A can use an attribute of item B and vice versa without
  # problems).
  class DependencyTracker

    attr_accessor :filename

    # The version of the file format used by the dependency tracker to store
    # dependencies. When a dependencies file with an incompatible version is
    # found, it is ignored.
    STORE_VERSION = 2

    # Creates a new dependency tracker for the given items.
    def initialize(items)
      @items          = items
      @filename       = 'tmp/dependencies'
      @graph          = Nanoc3::DirectedGraph.new([ nil ] + @items)
      @previous_items = []
    end

    # Starts listening for dependency messages (+:visit_started+ and
    # +:visit_ended+) and start recording dependencies.
    def start
      # Initialize dependency stack. An item will be pushed onto this stack
      # when it is visited. Therefore, an item on the stack always depends on
      # all items pushed above it.
      @stack = []

      # Register start of visits
      Nanoc3::NotificationCenter.on(:visit_started, self) do |item|
        # Record possible dependency
        unless @stack.empty?
          self.record_dependency(@stack[-1], item)
        end

        @stack.push(item)
      end

      # Register end of visits
      Nanoc3::NotificationCenter.on(:visit_ended, self) do |item|
        @stack.pop
      end
    end

    # Stop listening for dependency messages and stop recording dependencies.
    def stop
      # Unregister
      Nanoc3::NotificationCenter.remove(:visit_started, self)
      Nanoc3::NotificationCenter.remove(:visit_ended,   self)
    end

    # Returns the direct dependencies for +item+, i.e. the items that, when
    # outdated, will cause +item+ to be marked as outdated. Indirect
    # dependencies will not be returned (e.g. if A depends on B which depends
    # on C, then the direct dependencies of A do not include C).
    def direct_predecessors_of(item)
      @graph.direct_predecessors_of(item).compact
    end

    # Returns all dependencies (direct and indirect) for +item+, i.e. the
    # items that, when outdated, will cause +item+ to be marked as outdated.
    def predecessors_of(item)
      @graph.predecessors_of(item).compact
    end

    # Returns the direct inverse dependencies for +item+, i.e. the items that
    # will be marked as outdated when +item+ is outdated. Indirect
    # dependencies will not be returned (e.g. if A depends on B which depends
    # on C, then the direct inverse dependencies of C do not include A).
    def direct_successors_of(item)
      @graph.direct_successors_of(item).compact
    end

    # Returns all inverse dependencies (direct and indirect) for +item+, i.e.
    # the items that will be marked as outdated when +item+ is outdated.
    def successors_of(item)
      @graph.successors_of(item).compact
    end

    # Records a dependency from +src+ to +dst+ in the dependency graph. When
    # +dst+ is oudated, +src+ will also become outdated.
    def record_dependency(src, dst)
      # Warning! dst and src are *reversed* here!
      @graph.add_edge(dst, src) unless src == dst
    end

    # Stores the dependency graph into the file specified by the +filename+
    # attribute.
    def store_graph
      FileUtils.mkdir_p(File.dirname(self.filename))
      store = PStore.new(self.filename)
      store.transaction do
        store[:version]  = STORE_VERSION
        store[:vertices] = @graph.vertices.map { |i| i && i.identifier }
        store[:edges]    = @graph.edges
      end
    end

    # Loads the dependency graph from the file specified by the +filename+
    # attribute. This method will overwrite an existing dependency graph.
    def load_graph
      # Create new graph
      @graph = Nanoc3::DirectedGraph.new([ nil ] + @items)

      # Get store
      return if !File.file?(self.filename)
      store = PStore.new(self.filename)

      # Load dependencies
      store.transaction do
        # Verify version
        return if store[:version] != STORE_VERSION

        # Load vertices
        @previous_items = store[:vertices].map do |v|
          @items.find { |i| i.identifier == v }
        end

        # Load edges
        store[:edges].each do |edge|
          from_index, to_index = *edge
          from, to = @previous_items[from_index], @previous_items[to_index]
          @graph.add_edge(from, to)
        end
      end
    end

    # Traverses the dependency graph and marks all items that (directly or
    # indirectly) depend on an outdated item as outdated.
    def mark_outdated_items
      # Unmark everything
      @items.each { |i| i.outdated_due_to_dependencies = false }

      # Mark new items as outdated
      added_items = @items - @previous_items
      added_items.each { |i| i.outdated_due_to_dependencies = true }

      # Mark successors of nil as outdated
      self.successors_of(nil).each do |i|
        i.outdated_due_to_dependencies = true
      end

      # For each outdated item...
      @items.select { |i| i.outdated? }.each do |outdated_item|
        # ... mark all its successors as outdated
        self.successors_of(outdated_item).each do |i|
          i.outdated_due_to_dependencies = true
        end
      end
    end

    # Empties the list of dependencies for the given item. This is necessary
    # before recompiling the given item, because otherwise old dependencies
    # will stick around and new dependencies will appear twice. This function
    # removes all incoming edges for the given vertex.
    def forget_dependencies_for(item)
      @graph.vertices.each do |v|
        @graph.remove_edge(v, item)
      end
    end

    # Prints the dependency graph in human-readable form.
    def print_graph
      @items.each do |item|
        puts "#{item.inspect} depends on:"

        predecessors = direct_predecessors_of(item)
        predecessors.each do |pred|
          puts "    #{pred.inspect}"
        end
        puts "    (nothing!)" if predecessors.empty?
        puts
      end
    end

  private

    # Returns the item with the given identifier, or nil if no item is found.
    def item_with_identifier(identifier)
      @items.find { |i| i.identifier == identifier }
    end

  end

end
