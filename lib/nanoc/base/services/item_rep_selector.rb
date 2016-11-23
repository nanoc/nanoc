module Nanoc::Int
  # Yields item reps to compile.
  #
  # @api private
  class ItemRepSelector
    def initialize(reps)
      @reps = reps
    end

    def each
      graph = Nanoc::Int::DirectedGraph.new(@reps)

      loop do
        break if graph.roots.empty?
        rep = graph.roots.each { |e| break e }

        begin
          yield(rep)
          graph.delete_vertex(rep)
        rescue => e
          is_success = handle_error(e, rep, graph)
          raise(e) unless is_success
        end
      end

      # Check whether everything was compiled
      unless graph.vertices.empty?
        raise Nanoc::Int::Errors::RecursiveCompilation.new(graph.vertices)
      end
    end

    def handle_error(e, rep, graph)
      case e
      when Nanoc::Int::Errors::CompilationError
        handle_error(e.unwrap, rep, graph)
      when Nanoc::Int::Errors::UnmetDependency
        handle_dependency_error(e, rep, graph)
        true
      else
        false
      end
    end

    def handle_dependency_error(e, rep, graph)
      other_rep = e.rep
      graph.add_edge(other_rep, rep)
      unless graph.vertices.include?(other_rep)
        graph.add_vertex(other_rep)
      end
    end
  end
end
