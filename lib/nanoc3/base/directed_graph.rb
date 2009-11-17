# encoding: utf-8

module Nanoc3

  class DirectedGraph

    class SquareBooleanMatrix

      def initialize(size)
        @size = size
      end

      def [](x, y)
        @data ||= {}
        @data[x] ||= {}
        @data[x].has_key?(y) ? @data[x][y] : false
      end

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

    def initialize(vertices)
      @vertices = vertices

      @matrix = SquareBooleanMatrix.new(@vertices.size)
    end

    def add_edge(from, to)
      from_index, to_index = indices_of(from, to)
      @matrix[from_index, to_index] = true
    end

    def remove_edge(from, to)
      from_index, to_index = indices_of(from, to)
      @matrix[from_index, to_index] = false
    end

    def predecessors_of(to)
      @vertices.select do |from|
        from_index, to_index = indices_of(from, to)
        @matrix[from_index, to_index] == true
      end
    end

    def successors_of(from)
      @vertices.select do |to|
        from_index, to_index = indices_of(from, to)
        @matrix[from_index, to_index] == true
      end
    end

    def all_predecessors_of(vertex)
      recursively_find_vertices(vertex, :predecessors_of)
    end

    def all_successors_of(vertex)
      recursively_find_vertices(vertex, :successors_of)
    end

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

    def indices_of(*vertices)
      vertices.map { |v| @vertices.index(v) or raise RuntimeError, "#{v.inspect} not a vertex" }
    end

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
