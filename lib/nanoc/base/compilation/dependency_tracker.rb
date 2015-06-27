module Nanoc::Int
  # @api private
  class DependencyTracker
    def initialize(dependency_store)
      @dependency_store = dependency_store

      @stack = []
    end

    # Starts listening for dependency messages (`:visit_started` and
    # `:visit_ended`) and start recording dependencies.
    #
    # @return [void]
    def start
      # Initialize dependency stack. An object will be pushed onto this stack
      # when it is visited. Therefore, an object on the stack always depends
      # on all objects pushed above it.
      @stack = []

      # Register start of visits
      Nanoc::Int::NotificationCenter.on(:visit_started, self) do |obj|
        unless @stack.empty?
          Nanoc::Int::NotificationCenter.post(:dependency_created, @stack.last, obj)
          @dependency_store.record_dependency(@stack.last, obj)
        end
        @stack.push(obj)
      end

      # Register end of visits
      Nanoc::Int::NotificationCenter.on(:visit_ended, self) do |_obj|
        @stack.pop
      end
    end

    # Stop listening for dependency messages and stop recording dependencies.
    #
    # @return [void]
    def stop
      # Sanity check
      unless @stack.empty?
        raise 'Internal inconsistency: dependency tracker stack not empty at end of compilation'
      end

      # Unregister
      Nanoc::Int::NotificationCenter.remove(:visit_started, self)
      Nanoc::Int::NotificationCenter.remove(:visit_ended,   self)
    end

    # @return The topmost item on the stack, i.e. the one currently being
    #   compiled
    def top
      @stack.last
    end
  end
end
