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

    # Creates a new dependency tracker for the given items.
    def initialize(items)
      @items = items

      @filename = 'tmp/dependencies'

      @graph = {}
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
    def direct_dependencies_for(item)
      @graph[item] || []
    end

    # Returns all dependencies (direct and indirect) for +item+, i.e. the
    # items that, when outdated, will cause +item+ to be marked as outdated.
    def all_dependencies_for(item)
      direct_dependencies   = direct_dependencies_for(item)
      indirect_dependencies = direct_dependencies.map { |i| all_dependencies_for(i) }

      (direct_dependencies + indirect_dependencies).flatten
    end

    # Records a dependency from +src+ to +dst+ in the dependency graph. When
    # +dst+ is oudated, +src+ will also become outdated.
    def record_dependency(src, dst)
      @graph[src] ||= []

      # Don't include self in dependencies
      return if src == dst

      # Don't include doubles in dependencies
      return if @graph[src].include?(dst)

      # Record dependency
      @graph[src] << dst
    end

    # Stores the dependency graph into the file specified by the +filename+
    # attribute.
    def store_graph
      # Create dir
      FileUtils.mkdir_p(File.dirname(self.filename))

      # Complete the graph
      complete_graph

      # Convert graph of items into graph of item identifiers
      new_graph = {}
      @graph.each_pair do |second_item, first_items|
        # Don't store nil because that would be pointless (if first_item is
        # outdated, something that does not exist is also outdated… makes no
        # sense).
        # FIXME can second_item really be nil?
        next if second_item.nil?

        new_graph[second_item.identifier] = first_items.map { |f| f && f.identifier }.compact
      end

      # Store dependencies
      store = PStore.new(self.filename)
      store.transaction do
        store[:dependencies] = new_graph
      end
    end

    # Loads the dependency graph from the file specified by the +filename+
    # attribute. This method will overwrite an existing dependency graph.
    def load_graph
      # Create new graph
      @graph = {}

      # Don't do anything if dependencies haven't been stored yet
      return if !File.file?(self.filename)

      # Load dependencies
      store = PStore.new(self.filename)
      store.transaction do
        # Convert graph of identifiers into graph of items
        store[:dependencies].each_pair do |second_item_identifier, first_item_identifiers|
          # Convert second and first item identifiers into items
          second_item = item_with_identifier(second_item_identifier)
          first_items = first_item_identifiers.map { |p| item_with_identifier(p) }

          @graph[second_item] = first_items
        end
      end
    end

    # Traverses the dependency graph and marks all items that (directly or
    # indirectly) depend on an outdated item as outdated.
    def mark_outdated_items
      # Invert dependency graph
      inverted_graph = invert_graph(@graph)

      # Unmark everything
      @items.each { |i| i.dependencies_outdated = false }

      # Mark items that appear in @items but not in the dependency graph
      added_items = @items - @graph.keys
      added_items.each { |i| i.dependencies_outdated = true }

      # Walk graph and mark items as outdated if necessary
      # (#keys and #sort is used instead of #each_pair to add determinism)
      first_items = inverted_graph.keys.sort_by { |i| i.nil? ? '/' : i.identifier }
      something_changed = true
      while something_changed
        something_changed = false

        first_items.each do |first_item|
          second_items = inverted_graph[first_item]

          if first_item.nil? ||                # item was removed
             first_item.outdated? ||           # item itself is outdated
             first_item.dependencies_outdated? # item is outdated because of its dependencies
            second_items.each do |item|
              # Ignore this item
              next if item.nil?

              something_changed = true if !item.dependencies_outdated?
              item.dependencies_outdated = true
            end
          end
        end
      end
    end

    # Empties the list of dependencies for the given item. This is necessary
    # before recompiling the given item, because otherwise old dependencies
    # will stick around and new dependencies will appear twice.
    def forget_dependencies_for(item)
      @graph[item] = []
    end

  private

    # Returns the item with the given identifier, or nil if no item is found.
    def item_with_identifier(identifier)
      @items.find { |i| i.identifier == identifier }
    end

    # Inverts the given graph (keys become values and values become keys).
    #
    # For example, this graph
    #
    #   {
    #     :a => [ :b, :c ],
    #     :b => [ :x, :c ]
    #   }
    #
    # is turned into
    #
    #   {
    #     :b => [ :a ],
    #     :c => [ :a, :b ],
    #     :x => [ :b ]
    #   }
    def invert_graph(graph)
      inverted_graph = {}

      graph.each_pair do |key, values|
        values.each do |v|
          inverted_graph[v] ||= []
          inverted_graph[v] << key
        end
      end

      inverted_graph
    end

    # Ensures that all items in the dependency graph have a list of
    # dependecies, even if it is empty. Items without a list of dependencies
    # will be treated as "added" and will depend on all other pages, which is
    # not necessary for non-added items.
    def complete_graph
      @items.each do |item|
        @graph[item] ||= []
      end

    end

  end

end
