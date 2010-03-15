# encoding: utf-8

require 'set'

module Nanoc3

  # Represents a directed graph. It is used by the dependency tracker for
  # storing and querying dependencies between items.
  #
  # @example Creating and using a directed graph
  #
  #   # Create a graph with three vertices
  #   graph = DirectedGraph.new(%w( a b c d ))
  #   
  #   # Add edges
  #   graph.add_edge('a', 'b')
  #   graph.add_edge('b', 'c')
  #   graph.add_edge('c', 'd')
  #   
  #   # Get (direct) predecessors
  #   graph.direct_predecessors_of('d').sort
  #     # => %w( c )
  #   graph.predecessors_of('d').sort
  #     # => %w( a b c )
  #   
  #   # Modify edges
  #   graph.remove_edge('a', 'b')
  #   
  #   # Get (direct) predecessors again
  #   graph.direct_predecessors_of('d').sort
  #     # => %w( c )
  #   graph.predecessors_of('d').sort
  #     # => %w( b c )
  class DirectedGraph

    # The list of vertices in this graph.
    #
    # @return [Array]
    attr_reader :vertices

    # Creates a new directed graph with the given vertices.
    def initialize(vertices)
      @vertices = vertices

      @from_graph = {}
      @to_graph   = {}

      @vertice_indexes = {}
      vertices.each_with_index do |v, i|
        @vertice_indexes[v] = i
      end

      invalidate_caches
    end

    # Adds an edge from the first vertex to the second vertex.
    #
    # @param from Vertex where the edge should start
    # @param to   Vertex where the edge should end
    #
    # @return [void]
    def add_edge(from, to)
      @from_graph[from] ||= Set.new
      @from_graph[from] << to

      @to_graph[to] ||= Set.new
      @to_graph[to]  << from

      invalidate_caches
    end

    # Removes the edge from the first vertex to the second vertex. If the
    # edge does not exist, nothing is done.
    #
    # @param from Start vertex of the edge
    # @param to   End vertex of the edge
    #
    # @return [void]
    def remove_edge(from, to)
      @from_graph[from] ||= Set.new
      @from_graph[from].delete(to)

      @to_graph[to] ||= Set.new
      @to_graph[to].delete(from)

      invalidate_caches
    end

    # Deletes all edges going to the given vertex.
    #
    # @param to Vertex to which all edges should be removed
    #
    # @return [void]
    def delete_edges_to(to)
      @to_graph[to] ||= Set.new
      @to_graph[to].each do |from|
        @from_graph[from].delete(to)
      end
      @to_graph.delete(to)
    end

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

    # Returns an array of tuples representing the edges. The result of this
    # method may take a while to compute and should be cached if possible.
    #
    # @return [Array] The list of all edges in this graph.
    def edges
      result = []
      @vertices.each_with_index do |v, i|
        direct_successors_of(v).map { |v2| @vertice_indexes[v2] }.each do |i2|
          result << [ i, i2 ]
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
      unprocessed_vertices = [ start ]

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
