module Nanoc::Int
  # @api private
  class DependencyTracker
    def initialize(dependency_store)
      @dependency_store = dependency_store
    end

    # Record dependencies for the duration of the block.
    #
    # @return [void]
    def run
      unless block_given?
        raise ArgumentError, 'No block given'
      end

      stack = []
      start_tracking(stack)
      yield
    ensure
      stop_tracking(stack)
    end

    # @api private
    def start_tracking(stack)
      Nanoc::Int::NotificationCenter.on(:visit_started, self) do |obj|
        unless stack.empty?
          Nanoc::Int::NotificationCenter.post(:dependency_created, stack.last, obj)
          @dependency_store.record_dependency(stack.last, obj)
        end
        stack.push(obj)
      end

      Nanoc::Int::NotificationCenter.on(:visit_ended, self) do |_obj|
        stack.pop
      end
    end

    # @api private
    def stop_tracking(stack)
      unless stack.empty?
        raise 'Internal inconsistency: dependency tracker stack not empty at end of compilation'
      end

      Nanoc::Int::NotificationCenter.remove(:visit_started, self)
      Nanoc::Int::NotificationCenter.remove(:visit_ended,   self)
    end
  end
end
