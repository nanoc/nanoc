module Nanoc::Int
  # @api private
  class DependencyTracker
    class Null
      include Nanoc::Int::ContractsSupport

      contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout], C::KeywordArgs[raw_content: C::Optional[C::Bool], attributes: C::Optional[C::Bool], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
      def enter(_obj, raw_content: false, attributes: false, compiled_content: false, path: false)
      end

      contract C::None => C::Any
      def exit
      end

      contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout], C::KeywordArgs[raw_content: C::Optional[C::Bool], attributes: C::Optional[C::Bool], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
      def bounce(_obj, raw_content: false, attributes: false, compiled_content: false, path: false)
      end
    end

    include Nanoc::Int::ContractsSupport

    def initialize(dependency_store)
      @dependency_store = dependency_store
      @stack = []
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout], C::KeywordArgs[raw_content: C::Optional[C::Bool], attributes: C::Optional[C::Bool], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
    def enter(obj, raw_content: false, attributes: false, compiled_content: false, path: false)
      unless @stack.empty?
        Nanoc::Int::NotificationCenter.post(:dependency_created, @stack.last, obj)
        # TODO: use props
        @dependency_store.record_dependency(@stack.last, obj)
      end

      @stack.push(obj)
    end

    contract C::None => C::Any
    def exit
      @stack.pop
    end

    contract C::Or[Nanoc::Int::Item, Nanoc::Int::Layout], C::KeywordArgs[raw_content: C::Optional[C::Bool], attributes: C::Optional[C::Bool], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]] => C::Any
    def bounce(obj, raw_content: false, attributes: false, compiled_content: false, path: false)
      enter(obj, raw_content: raw_content, attributes: attributes, compiled_content: compiled_content, path: path)
      exit
    end
  end
end
