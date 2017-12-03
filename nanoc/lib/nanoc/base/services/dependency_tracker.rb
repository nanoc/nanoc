# frozen_string_literal: true

module Nanoc::Int
  # @api private
  class DependencyTracker
    include Nanoc::Int::ContractsSupport

    C_OBJ = C::Or[Nanoc::Int::Item, Nanoc::Int::Layout, Nanoc::Int::Configuration, Nanoc::Int::IdentifiableCollection]
    C_RAW_CONTENT = C::Or[C::IterOf[C::Or[String, Regexp]], C::Bool]
    C_ATTR = C::Or[C::IterOf[Symbol], C::Bool]
    C_ARGS = C::KeywordArgs[raw_content: C::Optional[C_RAW_CONTENT], attributes: C::Optional[C_ATTR], compiled_content: C::Optional[C::Bool], path: C::Optional[C::Bool]]

    class Null
      include Nanoc::Int::ContractsSupport

      contract C_OBJ, C_ARGS => C::Any
      def enter(_obj, raw_content: false, attributes: false, compiled_content: false, path: false); end

      contract C_OBJ => C::Any
      def exit; end

      contract C_OBJ, C_ARGS => C::Any
      def bounce(_obj, raw_content: false, attributes: false, compiled_content: false, path: false); end
    end

    def initialize(dependency_store)
      @dependency_store = dependency_store
      @stack = []
    end

    contract C_OBJ, C_ARGS => C::Any
    def enter(obj, raw_content: false, attributes: false, compiled_content: false, path: false)
      unless @stack.empty?
        Nanoc::Int::NotificationCenter.post(:dependency_created, @stack.last, obj)
        @dependency_store.record_dependency(
          @stack.last,
          obj,
          raw_content: raw_content,
          attributes: attributes,
          compiled_content: compiled_content,
          path: path,
        )
      end

      @stack.push(obj)
    end

    contract C_OBJ => C::Any
    def exit
      @stack.pop
    end

    contract C_OBJ, C_ARGS => C::Any
    def bounce(obj, raw_content: false, attributes: false, compiled_content: false, path: false)
      enter(obj, raw_content: raw_content, attributes: attributes, compiled_content: compiled_content, path: path)
      exit
    end
  end
end
