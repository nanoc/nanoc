module Nanoc::Int
  # @api private
  class DependencyStore < ::Nanoc::Int::Store
    # @return [Array<Nanoc::Int::Item, Nanoc::Int::Layout>]
    attr_reader :objects

    # @param [Array<Nanoc::Int::Item, Nanoc::Int::Layout>] objects
    def initialize(objects)
      super('tmp/dependencies', 4)

      @objects = objects
      @graph   = Nanoc::Int::DirectedGraph.new([nil] + @objects)
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
    # @param [Nanoc::Int::Item, Nanoc::Int::Layout] object The object for
    #   which to fetch the direct predecessors
    #
    # @return [Array<Nanoc::Int::Item, Nanoc::Int::Layout, nil>] The direct
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
    # @param [Nanoc::Int::Item, Nanoc::Int::Layout] object The object for which to
    #   fetch the direct successors
    #
    # @return [Array<Nanoc::Int::Item, Nanoc::Int::Layout>] The direct successors of
    #   the given object
    def objects_outdated_due_to(object)
      @graph.direct_successors_of(object).compact
    end

    # Records a dependency from `src` to `dst` in the dependency graph. When
    # `dst` is oudated, `src` will also become outdated.
    #
    # @param [Nanoc::Int::Item, Nanoc::Int::Layout] src The source of the dependency,
    #   i.e. the object that will become outdated if dst is outdated
    #
    # @param [Nanoc::Int::Item, Nanoc::Int::Layout] dst The destination of the
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
    # @param [Nanoc::Int::Item, Nanoc::Int::Layout] object The object for which to
    #   forget all dependencies
    #
    # @return [void]
    def forget_dependencies_for(object)
      @graph.delete_edges_to(object)
    end

    protected

    def data
      {
        edges: @graph.edges,
        vertices: @graph.vertices.map { |obj| obj && obj.reference },
      }
    end

    def data=(new_data)
      # Create new graph
      @graph = Nanoc::Int::DirectedGraph.new([nil] + @objects)

      # Load vertices
      previous_objects = new_data[:vertices].map do |reference|
        @objects.find { |obj| reference == obj.reference }
      end

      # Load edges
      new_data[:edges].each do |edge|
        from_index, to_index = *edge
        from = from_index && previous_objects[from_index]
        to   = to_index && previous_objects[to_index]
        @graph.add_edge(from, to)
      end

      # Record dependency from all items on new items
      new_objects = (@objects - previous_objects)
      new_objects.each do |new_obj|
        @objects.each do |obj|
          next unless obj.is_a?(Nanoc::Int::Item)
          @graph.add_edge(new_obj, obj)
        end
      end
    end
  end
end
