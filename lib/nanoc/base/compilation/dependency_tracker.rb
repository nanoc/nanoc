# encoding: utf-8

module Nanoc

  # Responsible for remembering dependencies between items and layouts. It is
  # used to speed up compilation by only letting an item be recompiled when it
  # is outdated or any of its dependencies (or dependencies’ dependencies,
  # etc) is outdated.
  #
  # The dependencies tracked by the dependency tracker are not dependencies
  # based on an item’s or a layout’s content. When one object uses an
  # attribute of another object, then this is also treated as a dependency.
  # While dependencies based on an item’s or layout’s content (handled in
  # {Nanoc::Compiler}) cannot be mutually recursive, the more general
  # dependencies in Nanoc::DependencyTracker can (e.g. item A can use an
  # attribute of item B and vice versa without problems).
  #
  # The dependency tracker remembers the dependency information between runs.
  # Dependency information is stored in the `tmp/dependencies` file.
  #
  # @api private
  class DependencyTracker < ::Nanoc::Store

    # @return [Array<Nanoc::Item, Nanoc::Layout>] The list of items and
    #   layouts that are being tracked by the dependency tracker
    attr_reader :objects

    # @return [Nanoc::Compiler] The compiler that corresponds to this
    #   dependency tracker
    attr_accessor :compiler

    # Creates a new dependency tracker for the given items and layouts.
    #
    # @param [Array<Nanoc::Item, Nanoc::Layout>] objects The list of items
    #   and layouts whose dependencies should be managed
    def initialize(objects)
      super('tmp/dependencies', 4)

      @objects = objects
      @graph   = Nanoc::DirectedGraph.new([ nil ] + @objects)
      @stack   = []
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
      Nanoc::NotificationCenter.on(:visit_started, self) do |obj|
        if !@stack.empty?
          Nanoc::NotificationCenter.post(:dependency_created, @stack.last, obj)
          self.record_dependency(@stack.last, obj)
        end
        @stack.push(obj)
      end

      # Register end of visits
      Nanoc::NotificationCenter.on(:visit_ended, self) do |obj|
        @stack.pop
      end
    end

    # Stop listening for dependency messages and stop recording dependencies.
    #
    # @return [void]
    def stop
      # Unregister
      Nanoc::NotificationCenter.remove(:visit_started, self)
      Nanoc::NotificationCenter.remove(:visit_ended,   self)
    end

    # @return The topmost item on the stack, i.e. the one currently being
    #   compiled
    #
    # @api private
    def top
      @stack.last
    end

    # Returns the direct dependencies for the given object.
    #
    # The direct dependencies of the given object include the items and
    # layouts that, when outdated will cause the given object to be marked as
    # outdated. Indirect dependencies will not be returned (e.g. if A depends
    # on B which depends on C, then the direct dependencies of A do not
    # include C).
    #
    # The direct predecessors can include nil, which indicates an item that is
    # no longer present in the site.
    #
    # @param [Nanoc::Item, Nanoc::Layout] object The object for
    #   which to fetch the direct predecessors
    #
    # @return [Array<Nanoc::Item, Nanoc::Layout, nil>] The direct
    # predecessors of
    #   the given object
    def objects_causing_outdatedness_of(object)
      @graph.direct_predecessors_of(object)
    end

    # Returns the direct inverse dependencies for the given object.
    #
    # The direct inverse dependencies of the given object include the objects
    # that will be marked as outdated when the given object is outdated.
    # Indirect dependencies will not be returned (e.g. if A depends on B which
    # depends on C, then the direct inverse dependencies of C do not include
    # A).
    #
    # @param [Nanoc::Item, Nanoc::Layout] object The object for which to
    #   fetch the direct successors
    #
    # @return [Array<Nanoc::Item, Nanoc::Layout>] The direct successors of
    #   the given object
    def objects_outdated_due_to(object)
      @graph.direct_successors_of(object).compact
    end

    # Records a dependency from `src` to `dst` in the dependency graph. When
    # `dst` is oudated, `src` will also become outdated.
    #
    # @param [Nanoc::Item, Nanoc::Layout] src The source of the dependency,
    #   i.e. the object that will become outdated if dst is outdated
    #
    # @param [Nanoc::Item, Nanoc::Layout] dst The destination of the
    #   dependency, i.e. the object that will cause the source to become
    #   outdated if the destination is outdated
    #
    # @return [void]
    def record_dependency(src, dst)
      # Warning! dst and src are *reversed* here!
      @graph.add_edge(dst, src) unless src == dst
    end

    # Empties the list of dependencies for the given object. This is necessary
    # before recompiling the given object, because otherwise old dependencies
    # will stick around and new dependencies will appear twice. This function
    # removes all incoming edges for the given vertex.
    #
    # @api private
    #
    # @param [Nanoc::Item, Nanoc::Layout] object The object for which to
    #   forget all dependencies
    #
    # @return [void]
    def forget_dependencies_for(object)
      @graph.delete_edges_to(object)
    end

    # @deprecated Use {#store} instead
    def store_graph
      self.store
    end

    # @deprecated Use {#load} instead
    def load_graph
      self.load
    end

    # @see Nanoc::Store#unload
    def unload
      @graph = Nanoc::DirectedGraph.new([ nil ] + @objects)
    end

  protected

    def data
      {
        :edges    => @graph.edges,
        :vertices => @graph.vertices.map { |obj| obj && obj.reference }
      }
    end

    def data=(new_data)
      # Create new graph
      @graph = Nanoc::DirectedGraph.new([ nil ] + @objects)

      # Load vertices
      previous_objects = new_data[:vertices].map do |reference|
        @objects.find { |obj| reference == obj.reference }
      end

      # Load edges
      new_data[:edges].each do |edge|
        from_index, to_index = *edge
        from = from_index && previous_objects[from_index]
        to   = to_index   && previous_objects[to_index]
        @graph.add_edge(from, to)
      end

      # Record dependency from all items on new items
      new_objects = (@objects - previous_objects)
      new_objects.each do |new_obj|
        @objects.each do |obj|
          next unless obj.is_a?(Nanoc::Item)
          @graph.add_edge(new_obj, obj)
        end
      end
    end

  end

end
