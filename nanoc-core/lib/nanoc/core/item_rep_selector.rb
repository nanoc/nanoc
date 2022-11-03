# frozen_string_literal: true

module Nanoc
  module Core
    # Yields item reps to compile.
    class ItemRepSelector
      def initialize(reps)
        @reps = reps
      end

      # An iterator (FIFO) over an array, with ability to ignore certain
      # elements.
      class ItemRepIgnorableIterator
        def initialize(array)
          @array = array.dup
        end

        def next_ignoring(ignored)
          elem = @array.shift
          elem = @array.shift while ignored.include?(elem)
          elem
        end
      end

      # A priority queue that tracks dependencies and can detect circular
      # dependencies.
      class ItemRepPriorityQueue
        def initialize(reps)
          # Prio A: most important; prio C: least important.
          @prio_a = []
          @prio_b = ItemRepIgnorableIterator.new(reps)
          @prio_c = []

          # Stack of things that depend on each other. This is used for
          # detecting and reporting circular dependencies.
          @stack = []

          # List of reps that we’ve already seen. Reps from `reps` will end up
          # in here. Reps can end up in here even *before* they come from
          # `reps`, when they are part of a dependency.
          @seen = Set.new
        end

        def next
          # Read prio A
          @this = @prio_a.pop
          if @this
            @stack.push(@this)
            return @this
          end

          # Read prio B
          @this = @prio_b.next_ignoring(@seen)
          if @this
            @stack.push(@this)
            return @this
          end

          # Read prio C
          @this = @prio_c.pop
          if @this
            @stack.push(@this)
            return @this
          end

          nil
        end

        def mark_ok
          @stack.pop
        end

        def mark_failed(dep)
          if @stack.include?(dep)
            raise Nanoc::Core::Errors::DependencyCycle.new(@stack + [dep])
          end

          # `@this` depends on `dep`, so `dep` has to be compiled first. Thus,
          # move `@this` into priority C, and `dep` into priority A.

          # Put `@this` (item rep that needs `dep` to be compiled first) into
          # priority C (lowest prio).
          @prio_c.push(@this)

          # Put `dep` (item rep that needs to be compiled first, before
          # `@this`) into priority A (highest prio).
          @prio_a.push(dep)

          # Remember that we’ve prioritised `dep`. This particular element will
          # come from @prio_b at some point in the future, so we’ll have to skip
          # it then.
          @seen << dep
        end
      end

      def each
        pq = ItemRepPriorityQueue.new(@reps)

        loop do
          rep = pq.next
          break if rep.nil?

          begin
            yield(rep)
            pq.mark_ok
          rescue => e
            actual_error = e.is_a?(Nanoc::Core::Errors::CompilationError) ? e.unwrap : e

            if actual_error.is_a?(Nanoc::Core::Errors::UnmetDependency)
              pq.mark_failed(actual_error.rep)
            else
              raise(e)
            end
          end
        end
      end
    end
  end
end
