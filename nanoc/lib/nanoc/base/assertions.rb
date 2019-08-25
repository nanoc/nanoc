# frozen_string_literal: true

module Nanoc
  module Assertions
    class AssertionFailure < Nanoc::Int::Errors::InternalInconsistency
    end

    module Mixin
      def assert(assertion)
        return unless Nanoc::Core::ContractsSupport.enabled?

        unless assertion.call
          raise AssertionFailure, "assertion failed: #{assertion.class}"
        end
      end
    end

    class Base
      def call
        raise NotImplementedError
      end
    end

    class AllItemRepsHaveCompiledContent < Nanoc::Assertions::Base
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[compiled_content_cache: C::Or[Nanoc::Core::CompiledContentCache, Nanoc::Core::TextualCompiledContentCache], item_reps: Nanoc::Core::ItemRepRepo] => C::Any
      def initialize(compiled_content_cache:, item_reps:)
        @compiled_content_cache = compiled_content_cache
        @item_reps = item_reps
      end

      contract C::None => C::Bool
      def call
        @item_reps.all? do |rep|
          @compiled_content_cache[rep]
        end
      end
    end

    class PathIsAbsolute < Nanoc::Assertions::Base
      include Nanoc::Core::ContractsSupport

      contract C::KeywordArgs[path: String] => C::Any
      def initialize(path:)
        @path = path
      end

      contract C::None => C::Bool
      def call
        Pathname.new(@path).absolute?
      end
    end
  end
end
