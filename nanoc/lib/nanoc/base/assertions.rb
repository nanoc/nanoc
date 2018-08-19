# frozen_string_literal: true

module Nanoc
  module Assertions
    class AssertionFailure < Nanoc::Int::Errors::InternalInconsistency
    end

    module Mixin
      def assert(assertion)
        return unless Nanoc::Int::ContractsSupport.enabled?

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
      def initialize(compiled_content_cache:, item_reps:)
        @compiled_content_cache = compiled_content_cache
        @item_reps = item_reps
      end

      def call
        @item_reps.all? do |rep|
          @compiled_content_cache[rep]
        end
      end
    end
  end
end
