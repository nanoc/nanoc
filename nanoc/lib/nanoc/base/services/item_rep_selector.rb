# frozen_string_literal: true

module Nanoc::Int
  # Yields item reps to compile.
  #
  # @api private
  class ItemRepSelector
    def initialize(reps)
      @reps = reps
    end

    class MicroGraph
      def initialize(reps)
        @reps = Set.new(reps)
        @stack = []
      end

      def next
        if @stack.any?
          @stack.last
        elsif @reps.any?
          @reps.each { |rep| break rep }.tap do |rep|
            @reps.delete(rep)
            @stack.push(rep)
          end
        else
          nil
        end
      end

      def mark_ok
        @stack.pop
      end

      def mark_failed(dep)
        if @stack.include?(dep)
          raise Nanoc::Int::Errors::DependencyCycle.new(@stack + [dep])
        end

        @reps.delete(dep)
        @stack.push(dep)
      end
    end

    def each
      mg = MicroGraph.new(@reps)

      loop do
        rep = mg.next
        break if rep.nil?

        begin
          yield(rep)
          mg.mark_ok
        rescue => e
          actual_error = e.is_a?(Nanoc::Int::Errors::CompilationError) ? e.unwrap : e

          if actual_error.is_a?(Nanoc::Int::Errors::UnmetDependency)
            mg.mark_failed(actual_error.rep)
          else
            raise(e)
          end
        end
      end
    end
  end
end
