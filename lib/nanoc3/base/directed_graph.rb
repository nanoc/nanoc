# encoding: utf-8

module Nanoc3

  # Nanoc3::DirectedGraph represents a directed graph. It is used by the
  # dependency tracker for storing and querying dependencies between items.
  class DirectedGraph

    # Nanoc3::DirectedGraph::SquareBooleanMatrix is, as the name says, a
    # square matrix that contains boolean values. It is used as an adjacency
    # matrix by the DirectedGraph class.
    class SquareBooleanMatrix

      # Creates a new matrix with the given number of rows/columns.
      def initialize(size)
        @size = size
      end

      # Gets the value at the given x/y coordinates.
      def [](x, y)
        @data ||= {}
        @data[x] ||= {}
        @data[x].has_key?(y) ? @data[x][y] : false
      end

      # Sets the value at the given x/y coordinates.
      def []=(x, y, value)
        @data ||= {}
        @data[x] ||= {}
        @data[x][y] = value
      end

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

    attr_reader :vertices

    # Creates a new directed graph with the given vertices.
    def initialize(vertices)
      @vertices = vertices

      @matrix = SquareBooleanMatrix.new(@vertices.size)
    end

    # Adds an edge from the first vertex to the second vertex.
    def add_edge(from, to)
      from_index, to_index = indices_of(from, to)
      @matrix[from_index, to_index] = true
    end

    # Removes the edge from the first vertex to the second vertex.
    def remove_edge(from, to)
      from_index, to_index = indices_of(from, to)
      @matrix[from_index, to_index] = false
    end

    # Returns the direct predecessors of the given vertex, i.e. the vertices
    # x where there is an edge from x to the given vertex y.
    def direct_predecessors_of(to)
      @vertices.select do |from|
        from_index, to_index = indices_of(from, to)
        @matrix[from_index, to_index] == true
      end
    end

    # Returns the direct successors of the given vertex, i.e. the vertices y
    # where there is an edge from the given vertex x to y.
    def direct_successors_of(from)
      @vertices.select do |to|
        from_index, to_index = indices_of(from, to)
        @matrix[from_index, to_index] == true
      end
    end

    # Returns the predecessors of the given vertex, i.e. the vertices x for
    # which there is a path from x to the given vertex y.
    def predecessors_of(vertex)
      recursively_find_vertices(vertex, :direct_predecessors_of)
    end

    # Returns the successors of the given vertex, i.e. the vertices y for
    # which there is a path from the given vertex x to y.
    def successors_of(vertex)
      recursively_find_vertices(vertex, :direct_successors_of)
    end

    # Returns an array of tuples representing the edges. The result of this
    # method may take a while to compute and should be cached if possible.
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
