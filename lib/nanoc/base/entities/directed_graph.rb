# frozen_string_literal: true

module Nanoc::Int
  # Represents a directed graph. It is used by the dependency tracker for
  # storing and querying dependencies between items.
  #
  # @example Creating and using a directed graph
  #
  #   # Create a graph with three vertices
  #   graph = Nanoc::Int::DirectedGraph.new(%w( a b c d e ))
  #
  #   # Add edges
  #   graph.add_edge('a', 'b')
  #   graph.add_edge('b', 'c')
  #   graph.add_edge('c', 'd')
  #   graph.add_edge('b', 'e')
  #
  #   # Get (direct) successors
  #   graph.direct_successors_of('a').sort
  #     # => %w( b )
  #   graph.successors_of('a').sort
  #     # => %w( b c d e )
  #
  #   # Modify edges
  #   graph.delete_edges_to('c')
  #
  #   # Get (direct) successors again
  #   graph.direct_successors_of('a').sort
  #     # => %w( b )
  #   graph.successors_of('a').sort
  #     # => %w( b e )
  #
  # @api private
  class DirectedGraph
    # @group Creating a graph

    # Creates a new directed graph with the given vertices.
    def initialize(vertices)
      @vertices = {}
      @next_vertex_idx = 0
      vertices.each do |v|
        @vertices[v] = @next_vertex_idx.tap { @next_vertex_idx += 1 }
      end

      @from_graph = {}
      @to_graph   = {}

      @edge_props = {}

      invalidate_caches
    end

    def inspect
      s = []

      @vertices.each_pair do |v1, _|
        direct_successors_of(v1).each do |v2|
          s << [v1.inspect + ' -> ' + v2.inspect + ' props=' + @edge_props[[v1, v2]].inspect]
        end
      end

      self.class.to_s + '(' + s.join(', ') + ')'
    end

    # @group Modifying the graph

    # Adds an edge from the first vertex to the second vertex.
    #
    # @param from Vertex where the edge should start
    #
    # @param to   Vertex where the edge should end
    #
    # @return [void]
    def add_edge(from, to, props: nil)
      add_vertex(from)
      add_vertex(to)

      @from_graph[from] ||= Set.new
      @from_graph[from] << to

      @to_graph[to] ||= Set.new
      @to_graph[to] << from

      if props
        @edge_props[[from, to]] = props
      end

      invalidate_caches
    end

    # Adds the given vertex to the graph.
    #
    # @param v The vertex to add to the graph
    #
    # @return [void]
    def add_vertex(v)
      return if @vertices.key?(v)

      @vertices[v] = @next_vertex_idx.tap { @next_vertex_idx += 1 }
    end

    # Deletes all edges going to the given vertex.
    #
    # @param to Vertex to which all edges should be removed
    #
    # @return [void]
    def delete_edges_to(to)
      return if @to_graph[to].nil?

      @to_graph[to].each do |from|
        @from_graph[from].delete(to)
        @edge_props.delete([from, to])
      end
      @to_graph.delete(to)

      invalidate_caches
    end

    # @group Querying the graph

    # Returns the direct predecessors of the given vertex, i.e. the vertices
    # x where there is an edge from x to the given vertex y.
    #
    # @param to The vertex of which the predecessors should be calculated
    #
    # @return [Array] Direct predecessors of the given vertex
    def direct_predecessors_of(to)
      @to_graph[to].to_a
    end

    # Returns the direct successors of the given vertex, i.e. the vertices y
    # where there is an edge from the given vertex x to y.
    #
    # @param from The vertex of which the successors should be calculated
    #
    # @return [Array] Direct successors of the given vertex
    def direct_successors_of(from)
      @from_graph[from].to_a
    end

    # Returns the predecessors of the given vertex, i.e. the vertices x for
    # which there is a path from x to the given vertex y.
    #
    # @param to The vertex of which the predecessors should be calculated
    #
    # @return [Array] Predecessors of the given vertex
    def predecessors_of(to)
      @predecessors[to] ||= recursively_find_vertices(to, :direct_predecessors_of)
    end

    # Returns the successors of the given vertex, i.e. the vertices y for
    # which there is a path from the given vertex x to y.
    #
    # @param from The vertex of which the successors should be calculated
    #
    # @return [Array] Successors of the given vertex
    def successors_of(from)
      @successors[from] ||= recursively_find_vertices(from, :direct_successors_of)
    end

    def props_for(from, to)
      @edge_props[[from, to]]
    end

    # @return [Array] The list of all vertices in this graph.
    def vertices
      @vertices.keys.sort_by { |v| @vertices[v] }
    end

    # Returns an array of tuples representing the edges. The result of this
    # method may take a while to compute and should be cached if possible.
    #
    # @return [Array] The list of all edges in this graph.
    def edges
      result = []
      @vertices.each_pair do |v1, i1|
        direct_successors_of(v1).map { |v2| [@vertices[v2], v2] }.each do |i2, v2|
          result << [i1, i2, @edge_props[[v1, v2]]]
        end
      end
      result
    end

    private

    # Invalidates cached data. This method should be called when the internal
    # graph representation is changed.
    def invalidate_caches
      @predecessors = {}
      @successors   = {}
    end

    # Recursively finds vertices, starting at the vertex start, using the
    # given method, which should be a symbol to a method that takes a vertex
    # and returns related vertices (e.g. predecessors, successors).
    def recursively_find_vertices(start, method)
      all_vertices = Set.new

      processed_vertices   = Set.new
      unprocessed_vertices = [start]

      until unprocessed_vertices.empty?
        # Get next unprocessed vertex
        vertex = unprocessed_vertices.pop
        next if processed_vertices.include?(vertex)
        processed_vertices << vertex

        # Add predecessors of this vertex
        send(method, vertex).each do |v|
          all_vertices << v unless all_vertices.include?(v)
          unprocessed_vertices << v
        end
      end

      all_vertices.to_a
    end
  end
end
