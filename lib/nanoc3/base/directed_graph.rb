# encoding: utf-8

module Nanoc3

  # Represents a directed graph. It is used by the dependency tracker for
  # storing and querying dependencies between items. Internally, the graph
  # will be stored as an adjacency matrix. For this, the
  # {Nanoc3::DirectedGraph::SquareBooleanMatrix} class is used.
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

    # A square matrix that contains boolean values. It is used as an adjacency
    # matrix by the {Nanoc3::DirectedGraph} class.
    #
    # This class is a helper class, which means that it is not used directly
    # by nanoc. Future versions of nanoc may no longer contain this class. Do
    # not depend on this class to be available.
    class SquareBooleanMatrix

      # Creates a new matrix with the given number of rows/columns.
      #
      # @param [Number] size The number of elements along both sides of the
      # matrix (in other words, the square root of the number of elements)
      def initialize(size)
        @size = size
      end

      # Gets the value at the given x/y coordinates.
      #
      # @param [Number] x The X coordinate
      # @param [Number] y The Y coordinate
      #
      # @return The value at the given coordinates
      def [](x, y)
        @data ||= {}
        @data[x] ||= {}
        @data[x].has_key?(y) ? @data[x][y] : false
      end

      # Sets the value at the given x/y coordinates.
      #
      # @param [Number] x The X coordinate
      # @param [Number] y The Y coordinate
      # @param value The value to set at the given coordinates
      #
      # @return [void]
      def []=(x, y, value)
        @data ||= {}
        @data[x] ||= {}
        @data[x][y] = value
      end

      # Returns a string representing this matrix in ASCII art.
      #
      # @return [String] The string representation of this matrix
      def to_s
        s = ''

        # Calculate column width
        width = (@size-1).to_s.size

        # Add header
        s << ' ' + ' '*width + ' '
        @size.times { |i| s << '| ' + format("%#{width}i", i) + ' ' }
        s << "\n"

        # Add rows
        @size.times do |x|
          # Add line
          s << '-' + '-'*width + '-'
          @size.times { |i| s << '+-' + '-'*width + '-' }
          s << "\n"

          # Add actual row
          s << ' ' + format("%#{width}i", x)+ ' '
          @size.times do |y|
            s << '| ' + format("%#{width}s", self[x, y] ? '*' : ' ') + ' '
          end
          s << "\n"
        end

        # Done
        s
      end

    end

    # The list of vertices in this graph.
    #
    # @return [Array]
    attr_reader :vertices

    # Creates a new directed graph with the given vertices.
    def initialize(vertices)
      @vertices = vertices

      @matrix = SquareBooleanMatrix.new(@vertices.size)
    end

    # Adds an edge from the first vertex to the second vertex.
    #
    # @param from Vertex where the edge should start
    # @param to   Vertex where the edge should end
    #
    # @return [void]
    def add_edge(from, to)
      from_index, to_index = indices_of(from, to)
      @matrix[from_index, to_index] = true
    end

    # Removes the edge from the first vertex to the second vertex. If the
    # edge does not exist, nothing is done.
    #
    # @param from Start vertex of the edge
    # @param to   End vertex of the edge
    #
    # @return [void]
    def remove_edge(from, to)
      from_index, to_index = indices_of(from, to)
      @matrix[from_index, to_index] = false
    end

    # Returns the direct predecessors of the given vertex, i.e. the vertices
    # x where there is an edge from x to the given vertex y.
    #
    # @param to The vertex of which the predecessors should be calculated
    #
    # @return [Array] Direct predecessors of the given vertex
    def direct_predecessors_of(to)
      @vertices.select do |from|
        from_index, to_index = indices_of(from, to)
        @matrix[from_index, to_index] == true
      end
    end

    # Returns the direct successors of the given vertex, i.e. the vertices y
    # where there is an edge from the given vertex x to y.
    #
    # @param from The vertex of which the successors should be calculated
    #
    # @return [Array] Direct successors of the given vertex
    def direct_successors_of(from)
      @vertices.select do |to|
        from_index, to_index = indices_of(from, to)
        @matrix[from_index, to_index] == true
      end
    end

    # Returns the predecessors of the given vertex, i.e. the vertices x for
    # which there is a path from x to the given vertex y.
    #
    # @param to The vertex of which the predecessors should be calculated
    #
    # @return [Array] Predecessors of the given vertex
    def predecessors_of(to)
      recursively_find_vertices(to, :direct_predecessors_of)
    end

    # Returns the successors of the given vertex, i.e. the vertices y for
    # which there is a path from the given vertex x to y.
    #
    # @param from The vertex of which the successors should be calculated
    #
    # @return [Array] Successors of the given vertex
    def successors_of(from)
      recursively_find_vertices(from, :direct_successors_of)
    end

    # Returns an array of tuples representing the edges. The result of this
    # method may take a while to compute and should be cached if possible.
    #
    # @return [Array] The list of all edges in this graph.
    def edges
      result = []

      @vertices.each do |from|
        @vertices.each do |to|
          from_index, to_index = indices_of(from, to)
          next if @matrix[from_index, to_index] == false

          result << [ from_index, to_index ]
        end
      end

      result
    end

    # Returns a string representing this graph in ASCII art (or, to be more
    # precise, the string representation of the matrix backing this graph).
    #
    # @return [String] The string representation of this graph
    def to_s
      @matrix.to_s
    end

  private

    # Returns an array of indices for the given vertices. Raises an error if
    # one or more given objects are not vertices.
    def indices_of(*vertices)
      vertices.map { |v| @vertices.index(v) or raise RuntimeError, "#{v.inspect} not a vertex" }
    end

    # Recursively finds vertices, starting at the vertex start, using the
    # given method, which should be a symbol to a method that takes a vertex
    # and returns related vertices (e.g. predecessors, successors).
    def recursively_find_vertices(start, method)
      all_vertices = []

      processed_vertices   = []
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

      all_vertices
    end

  end

end
