# frozen_string_literal: true

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

      prio_dependent = Set.new
      prio_in_progress = Set.new
      loop do
        rep = find(graph, prio_dependent, prio_in_progress)
        break if NONE.equal?(rep)

        begin
          prio_in_progress << rep
          yield(rep)
          prio_in_progress.delete(rep)
          graph.delete_vertex(rep)
        rescue => e
          handle_error(e, rep, graph, prio_dependent)
        end
      end

      # Check whether everything was compiled
      unless graph.vertices.empty?
        raise Nanoc::Int::Errors::DependencyCycle.new(graph)
      end
    end

    def find(graph, prio_dependent, prio_in_progress)
      if graph.roots.empty?
        NONE
      elsif prio_dependent.any?
        find_prio(graph, prio_dependent, prio_dependent, prio_in_progress)
      elsif prio_in_progress.any?
        find_prio(graph, prio_in_progress, prio_dependent, prio_in_progress)
      else
        graph.roots.each { |e| break e }
      end
    end

    def find_prio(graph, prio, prio_dependent, prio_in_progress)
      until prio.empty?
        rep = prio.each { |e| break e }
        if graph.roots.include?(rep)
          return rep
        else
          prio.delete(rep)
        end
      end

      find(graph, prio_dependent, prio_in_progress)
    end

    def handle_error(e, rep, graph, prio_dependent)
      actual_error =
        if e.is_a?(Nanoc::Int::Errors::CompilationError)
          e.unwrap
        else
          e
        end

      if actual_error.is_a?(Nanoc::Int::Errors::UnmetDependency)
        handle_dependency_error(actual_error, rep, graph, prio_dependent)
      else
        raise(e)
      end
    end

    def handle_dependency_error(e, rep, graph, prio_dependent)
      other_rep = e.rep
      prio_dependent << other_rep
      graph.add_edge(other_rep, rep)
      unless graph.vertices.include?(other_rep)
        graph.add_vertex(other_rep)
      end
    end
  end
end
