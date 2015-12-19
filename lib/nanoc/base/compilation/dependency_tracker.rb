module Nanoc::Int
  # @api private
  class DependencyTracker
    class Null
      def enter(_obj)
      end

      def exit(_obj)
      end

      def bounce(_obj)
      end
    end

    def initialize(dependency_store)
      @dependency_store = dependency_store
      @stack = []
    end

    def enter(obj)
      unless @stack.empty?
        Nanoc::Int::NotificationCenter.post(:dependency_created, @stack.last, obj)
        @dependency_store.record_dependency(@stack.last, obj)
      end

      @stack.push(obj)
    end

    def exit(_obj)
      @stack.pop
    end

    def bounce(obj)
      enter(obj)
      exit(obj)
    end
  end
end
