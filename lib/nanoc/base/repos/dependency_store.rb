module Nanoc::Int
  # @api private
  class DependencyStore < ::Nanoc::Int::Store
    # A dependency between two items/layouts.
    class Dependency
      include Nanoc::Int::ContractsSupport

      contract C::None => C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]]
      attr_reader :from

      contract C::None => C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]]
      attr_reader :to

      contract C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]], C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]], C::KeywordArgs[raw_content: C::Optional[C::Bool], attributes: C::Optional[C::Bool], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
      def initialize(from, to, raw_content:, attributes:, compiled_content:, path:)
        @from             = from
        @to               = to

        @raw_content      = raw_content
        @attributes       = attributes
        @compiled_content = compiled_content
        @path             = path
      end

      contract C::None => String
      def inspect
        s = "Dependency(#{@from.inspect} -> #{@to.inspect}, "
        s << (raw_content? ? 'r' : '_')
        s << (attributes? ? 'a' : '_')
        s << (compiled_content? ? 'c' : '_')
        s << (path? ? 'p' : '_')
        s << ')'
        s
      end

      contract C::None => C::Bool
      def raw_content?
        @raw_content
      end

      contract C::None => C::Bool
      def attributes?
        @attributes
      end

      contract C::None => C::Bool
      def compiled_content?
        @compiled_content
      end

      contract C::None => C::Bool
      def path?
        @path
      end

      contract C::None => C::Bool
      def only_attributes?
        @attributes && !@raw_content && !@compiled_content && !@path
      end

      contract C::None => C::Bool
      def only_raw_content?
        @raw_content && !@attributes && !@compiled_content && !@path
      end
    end

    include Nanoc::Int::ContractsSupport

    # @return [Array<Nanoc::Int::Item, Nanoc::Int::Layout>]
    attr_accessor :objects

    # @param [Array<Nanoc::Int::Item, Nanoc::Int::Layout>] objects
    def initialize(objects, env_name: nil)
      super(Nanoc::Int::Store.tmp_path_for(env_name: env_name, store_name: 'dependencies'), 4)

      @objects = objects
      @graph   = Nanoc::Int::DirectedGraph.new([nil] + @objects)
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::ItemRep, Nanoc::Int::Layout] => C::ArrayOf[Dependency]
    def dependencies_causing_outdatedness_of(object)
      objects_causing_outdatedness_of(object).map do |other_object|
        props = @graph.props_for(other_object, object) || {}

        Dependency.new(
          other_object,
          object,
          raw_content: props.fetch(:raw_content, false),
          attributes: props.fetch(:attributes, false),
          compiled_content: props.fetch(:compiled_content, false),
          path: props.fetch(:path, false),
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

    contract C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]], C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]], C::KeywordArgs[raw_content: C::Optional[C::Bool], attributes: C::Optional[C::Bool], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
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
      existing_props = @graph.props_for(dst, src) || {}
      new_props = { raw_content: raw_content, attributes: attributes, compiled_content: compiled_content, path: path }
      props = merge_props(existing_props, new_props)

      # Warning! dst and src are *reversed* here!
      @graph.add_edge(dst, src, props: props) unless src == dst
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

    def merge_props(p1, p2)
      keys = (p1.keys + p2.keys).uniq
      keys.each_with_object({}) do |key, memo|
        memo[key] = p1.fetch(key, false) || p2.fetch(key, false)
      end
    end

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
        from_index, to_index, props = *edge
        from = from_index && previous_objects[from_index]
        to   = to_index && previous_objects[to_index]
        @graph.add_edge(from, to, props: props)
      end

      # Record dependency from all items on new items
      new_objects = (@objects - previous_objects)
      new_props = { raw_content: true, attributes: true, compiled_content: true, path: true }
      new_objects.each do |new_obj|
        @objects.each do |obj|
          next unless obj.is_a?(Nanoc::Int::Item)
          @graph.add_edge(new_obj, obj, props: new_props)
        end
      end
    end
  end
end
