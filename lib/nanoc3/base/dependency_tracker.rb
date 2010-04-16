# encoding: utf-8

require 'pstore'

module Nanoc3

  # Responsible for remembering dependencies between items and layouts. It is
  # used to speed up compilation by only letting an item be recompiled when it
  # is outdated or any of its dependencies (or dependencies’ dependencies,
  # etc) is outdated.
  #
  # The dependencies tracked by the dependency tracker are not dependencies
  # based on an item’s or a layout’s content. When one object uses an
  # attribute of another object, then this is also treated as a dependency.
  # While dependencies based on an item’s or layout’s content (handled in
  # {Nanoc3::Compiler}) cannot be mutually recursive, the more general
  # dependencies in Nanoc3::DependencyTracker can (e.g. item A can use an
  # attribute of item B and vice versa without problems).
  #
  # The dependency tracker remembers the dependency information between runs.
  # Dependency information is stored in the `tmp/dependencies` file. This file
  # also contains a version number; when a dependencies file with an
  # incompatible version is found, it is ignored.
  class DependencyTracker

    # @return [String] The name of the file in which dependency information is
    #   stored
    attr_accessor :filename

    # @return [Array<Nanoc3::Item, Nanoc3::Layout>] The list of items and
    #   layouts that are being tracked by the dependency tracker
    attr_reader :objects

    # The version of the file format used to store dependencies.
    STORE_VERSION = 3

    # Creates a new dependency tracker for the given items and layouts.
    #
    # @param [Array<Nanoc3::Item, Nanoc3::Layout>] objects The list of items
    #   and layouts whose dependencies should be managed
    def initialize(objects)
      @objects = objects

      @filename         = 'tmp/dependencies'
      @graph            = Nanoc3::DirectedGraph.new([ nil ] + @objects)
      @previous_objects = []
    end

    # Starts listening for dependency messages (`:visit_started` and
    # `:visit_ended`) and start recording dependencies.
    #
    # @return [void]
    def start
      # Initialize dependency stack. An object will be pushed onto this stack
      # when it is visited. Therefore, an object on the stack always depends
      # on all objects pushed above it.
      @stack = []

      # Register start of visits
      Nanoc3::NotificationCenter.on(:visit_started, self) do |obj|
        self.record_dependency(@stack[-1], obj) unless @stack.empty?
        @stack.push(obj)
      end

      # Register end of visits
      Nanoc3::NotificationCenter.on(:visit_ended, self) do |obj|
        @stack.pop
      end
    end

    # Stop listening for dependency messages and stop recording dependencies.
    #
    # @return [void]
    def stop
      # Unregister
      Nanoc3::NotificationCenter.remove(:visit_started, self)
      Nanoc3::NotificationCenter.remove(:visit_ended,   self)
    end

    # Returns the direct dependencies for the given object.
    #
    # The direct dependencies of the given object include the items
    # and layouts that, when outdated will cause the given object to be marked
    # as outdated. Indirect dependencies will not be returned (e.g. if A
    # depends on B which depends on C, then the direct dependencies of A do
    # not include C).
    #
    # @param [Nanoc3::Item, Nanoc3::Layout] object The object for
    #   which to fetch the direct predecessors
    #
    # @return [Array<Nanoc3::Item, Nanoc3::Layout>] The direct predecessors of
    #   the given object
    def direct_predecessors_of(object)
      @graph.direct_predecessors_of(object).compact
    end

    # Returns all dependencies (direct and indirect) for the given object.
    #
    # The dependencies of given object include the objects that, when
    # outdated, will cause the given object to be marked as outdated.
    #
    # @param [Nanoc3::Item, Nanoc3::Layout] object The object for which to
    #   fetch all direct and indirect predecessors
    #
    # @return [Array<Nanoc3::Item, Nanoc3::Layout>] The predecessors of the
    #   given object
    def predecessors_of(object)
      @graph.predecessors_of(object).compact
    end

    # Returns the direct inverse dependencies for the given object.
    #
    # The direct inverse dependencies of the given object include the objects
    # that will be marked as outdated when the given object is outdated.
    # Indirect dependencies will not be returned (e.g. if A depends on B which
    # depends on C, then the direct inverse dependencies of C do not include
    # A).
    #
    # @param [Nanoc3::Item, Nanoc3::Layout] object The object for which to
    #   fetch the direct successors
    #
    # @return [Array<Nanoc3::Item, Nanoc3::Layout>] The direct successors of
    #   the given object
    def direct_successors_of(object)
      @graph.direct_successors_of(object).compact
    end

    # Returns all inverse dependencies (direct and indirect) for the given
    # object.
    #
    # The inverse dependencies of the given object include the objects that
    # will be marked as outdated when the given object is outdated.
    #
    # @param [Nanoc3::Item, Nanoc3::Layout] object The object for which to
    #   fetch all direct and indirect successors
    #
    # @return [Array<Nanoc3::Item, Nanoc3::Layout>] The successors of the
    #   given object
    def successors_of(object)
      @graph.successors_of(object).compact
    end

    # Records a dependency from `src` to `dst` in the dependency graph. When
    # `dst` is oudated, `src` will also become outdated.
    #
    # @param [Nanoc3::Item, Nanoc3::Layout] src The source of the dependency,
    #   i.e. the object that will become outdated if dst is outdated
    #
    # @param [Nanoc3::Item, Nanoc3::Layout] dst The destination of the
    #   dependency, i.e. the object that will cause the source to become
    #   outdated if the destination is outdated
    #
    # @return [void]
    def record_dependency(src, dst)
      # Warning! dst and src are *reversed* here!
      @graph.add_edge(dst, src) unless src == dst
    end

    # Stores the dependency graph into the file specified by the {#filename}
    # attribute.
    #
    # @return [void]
    def store_graph
      FileUtils.mkdir_p(File.dirname(self.filename))
      store = PStore.new(self.filename)
      store.transaction do
        store[:version]  = STORE_VERSION
        store[:vertices] = @graph.vertices.map { |obj| obj && obj.reference }
        store[:edges]    = @graph.edges
      end
    end

    # Loads the dependency graph from the file specified by the {#filename}
    # attribute. This method will overwrite an existing dependency graph.
    #
    # @return [void]
    def load_graph
      # Create new graph
      @graph = Nanoc3::DirectedGraph.new([ nil ] + @objects)

      # Get store
      return if !File.file?(self.filename)
      store = PStore.new(self.filename)

      # Load dependencies
      store.transaction do
        # Verify version
        return if store[:version] != STORE_VERSION

        # Load vertices
        @previous_objects = store[:vertices].map do |reference|
          @objects.find { |obj| reference == obj.reference }
        end

        # Load edges
        store[:edges].each do |edge|
          from_index, to_index = *edge
          from, to = @previous_objects[from_index], @previous_objects[to_index]
          @graph.add_edge(from, to)
        end
      end
    end

    # Traverses the dependency graph and marks all objects that (directly or
    # indirectly) depend on an outdated object as outdated.
    #
    # @return [void]
    def propagate_outdatedness
      # Unmark everything
      @objects.each { |o| o.outdated_due_to_dependencies = false }

      # Mark new objects as outdated
      added_objects = @objects - @previous_objects
      added_objects.each { |o| o.outdated_due_to_dependencies = true }

      # Mark successors of nil as outdated
      self.successors_of(nil).each do |o|
        o.outdated_due_to_dependencies = true
      end

      # Mark successors of outdated objects as outdated
      require 'set'
      unprocessed = @objects.select { |o| o.outdated? }
      seen        = Set.new(unprocessed)
      until unprocessed.empty?
        obj = unprocessed.shift

        self.direct_successors_of(obj).each do |successor|
          next if seen.include?(successor)
          seen << successor

          successor.outdated_due_to_dependencies = true
          unprocessed << successor
        end
      end
    end

    # Empties the list of dependencies for the given object. This is necessary
    # before recompiling the given object, because otherwise old dependencies
    # will stick around and new dependencies will appear twice. This function
    # removes all incoming edges for the given vertex.
    #
    # @param [Nanoc3::Item, Nanoc3::Layout] object The object for which to
    #   forget all dependencies
    #
    # @return [void]
    def forget_dependencies_for(object)
      @graph.delete_edges_to(object)
    end

    # @deprecated Use {#propagate_outdatedness} instead.
    def mark_outdated_items
      propagate_outdatedness
    end

  end

end
