module Nanoc::Int
  # @api private
  class DependencyStore < ::Nanoc::Int::Store
    include Nanoc::Int::ContractsSupport

    attr_accessor :items
    attr_accessor :layouts

    def initialize(items, layouts, site: nil)
      super(Nanoc::Int::Store.tmp_path_for(site: site, store_name: 'dependencies'), 4)

      @items = items
      @layouts = layouts

      @new_objects = []
      @graph = Nanoc::Int::DirectedGraph.new([nil] + @items.to_a + @layouts.to_a)
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::ArrayOf[Nanoc::Int::Dependency]
    def dependencies_causing_outdatedness_of(object)
      objects_causing_outdatedness_of(object).map do |other_object|
        props = props_for(other_object, object)

        Nanoc::Int::Dependency.new(
          other_object,
          object,
          Nanoc::Int::Props.new(
            raw_content: props.fetch(:raw_content, false),
            attributes: props.fetch(:attributes, false),
            compiled_content: props.fetch(:compiled_content, false),
            path: props.fetch(:path, false),
          ),
        )
      end
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
      if @new_objects.any?
        [@new_objects.first]
      else
        @graph.direct_predecessors_of(object)
      end
    end

    C_DOC = C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]
    C_ATTR = C::Or[C::IterOf[Symbol], C::Bool]
    contract C::Maybe[C_DOC], C::Maybe[C_DOC], C::KeywordArgs[raw_content: C::Optional[C::Bool], attributes: C::Optional[C_ATTR], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
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
    def record_dependency(src, dst, raw_content: false, attributes: false, compiled_content: false, path: false)
      existing_props = Nanoc::Int::Props.new(@graph.props_for(dst, src) || {})
      new_props = Nanoc::Int::Props.new(raw_content: raw_content, attributes: attributes, compiled_content: compiled_content, path: path)
      props = existing_props.merge(new_props)

      @graph.add_edge(dst, src, props: props.to_h) unless src == dst
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

    def props_for(a, b)
      props = @graph.props_for(a, b) || {}

      if props.values.any? { |v| v }
        props
      else
        { raw_content: true, attributes: true, compiled_content: true, path: true }
      end
    end

    def data
      {
        edges: @graph.edges,
        vertices: @graph.vertices.map { |obj| obj && obj.reference },
      }
    end

    def data=(new_data)
      objects = @items.to_a + @layouts.to_a

      # Create new graph
      @graph = Nanoc::Int::DirectedGraph.new([nil] + objects)

      # Load vertices
      previous_objects = new_data[:vertices].map do |reference|
        if reference
          case reference[0]
          when :item
            @items.object_with_identifier(reference[1])
          when :layout
            @layouts.object_with_identifier(reference[1])
          else
            raise Nanoc::Int::Errors::InternalInconsistency, "unrecognised reference #{reference[0].inspect}"
          end
        else
          nil
        end
      end

      # Load edges
      new_data[:edges].each do |edge|
        from_index, to_index, props = *edge
        from = from_index && previous_objects[from_index]
        to   = to_index && previous_objects[to_index]
        @graph.add_edge(from, to, props: props)
      end

      # Record dependency from all items on new items
      @new_objects = objects - previous_objects
    end
  end
end
