module Nanoc::Int
  # Yields item reps to compile.
  #
  # @api private
  class ItemRepSelector
    def initialize(reps)
      @reps = reps
    end

    NONE = Object.new

    def each
      graph = Nanoc::Int::DirectedGraph.new(@reps)

      prioritised = Set.new
      loop do
        rep = next(graph, prioritised)
        break if NONE.equal?(rep)

        begin
          yield(rep)
          graph.delete_vertex(rep)
        rescue => e
          handle_error(e, rep, graph, prioritised)
        end
      end

      # Check whether everything was compiled
      unless graph.vertices.empty?
        raise Nanoc::Int::Errors::RecursiveCompilation.new(graph.vertices)
      end
    end

    def next(graph, _prioritised)
      if graph.roots.empty?
        NONE
      else
        graph.roots.each { |e| break e }
      end
    end

    def handle_error(e, rep, graph, prioritised)
      actual_error =
        if e.is_a?(Nanoc::Int::Errors::CompilationError)
          e.unwrap
        else
          e
        end

      if actual_error.is_a?(Nanoc::Int::Errors::UnmetDependency)
        handle_dependency_error(actual_error, rep, graph, prioritised)
      else
        raise(e)
      end
    end

    def handle_dependency_error(e, rep, graph, prioritised)
      other_rep = e.rep
      prioritised << other_rep
      graph.add_edge(other_rep, rep)
      unless graph.vertices.include?(other_rep)
        graph.add_vertex(other_rep)
      end
    end
  end
end
