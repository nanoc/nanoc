# frozen_string_literal: true

module Nanoc
  module Core
    # Yields item reps to compile.
    class ItemRepSelector
      def initialize(reps)
        @reps = reps
      end

      # A priority queue that tracks dependencies and can detect circular
      # dependencies.
      class ItemRepPriorityQueue
        def initialize(reps)
          # Prio A: most important; prio C: least important.
          @prio_a = nil
          @prio_b = reps.dup
          @prio_c = []

          # List of reps that we’ve already seen. Reps from `reps` will end up
          # in here. Reps can end up in here even *before* they come from
          # `reps`, when they are part of a dependency.
          @seen = Set.new

          # List of reps that have already been completed (yielded followed by
          # `#mark_ok`).
          @completed = Set.new

          # Record (hard) dependencies. Used for detecting cycles.
          @dependencies = Hash.new { |hash, key| hash[key] = Set.new }
        end

        def next
          # Read prio A
          @this = @prio_a
          if @this
            @prio_a = nil
            return @this
          end

          # Read prio B
          @this = @prio_b.shift
          @this = @prio_b.shift while @seen.include?(@this)
          if @this
            return @this
          end

          # Read prio C
          @this = @prio_c.pop
          @this = @prio_c.pop while @completed.include?(@this)
          if @this
            return @this
          end

          nil
        end

        def mark_ok
          @completed << @this
        end

        def mark_failed(dep)
          record_dependency(dep)

          # `@this` depends on `dep`, so `dep` has to be compiled first. Thus,
          # move `@this` into priority C, and `dep` into priority A.

          # Put `@this` (item rep that needs `dep` to be compiled first) into
          # priority C (lowest prio).
          @prio_c.push(@this) unless @prio_c.include?(@this)

          # Put `dep` (item rep that needs to be compiled first, before
          # `@this`) into priority A (highest prio).
          @prio_a = dep

          # Remember that we’ve prioritised `dep`. This particular element will
          # come from @prio_b at some point in the future, so we’ll have to skip
          # it then.
          @seen << dep
        end

        private

        def record_dependency(dep)
          @dependencies[@this] << dep

          find_cycle(@this, [@this])
        end

        def find_cycle(dep, path)
          @dependencies[dep].each do |dep1|
            # Check whether this dependency path ends in `@this` again. If it
            # does, we have a cycle (because we started from `@this`).
            if dep1 == @this
              raise Nanoc::Core::Errors::DependencyCycle.new(path)
            end

            # Continue checking, starting from `dep1` this time.
            find_cycle(dep1, [*path, dep1])
          end
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
