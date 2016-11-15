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

    include Nanoc::Int::ContractsSupport

    def initialize(dependency_store)
      @dependency_store = dependency_store
      @stack = []
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout], C::KeywordArgs[hard: C::Optional[C::Bool]] => C::Any
    def enter(obj, hard: false)
      unless @stack.empty?
        Nanoc::Int::NotificationCenter.post(:dependency_created, @stack.last, obj)
        @dependency_store.record_dependency(@stack.last, obj)
      end

      @stack.push(obj)
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout] => C::Any
    def exit(_obj)
      @stack.pop
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout], C::KeywordArgs[hard: C::Optional[C::Bool]] => C::Any
    def bounce(obj, hard: false)
      enter(obj, hard: hard)
      exit(obj)
    end
  end
end
