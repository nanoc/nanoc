# frozen_string_literal: true

module Nanoc
  module Core
    # @api private
    class DependencyTracker
      include Nanoc::Core::ContractsSupport

      C_OBJ =
        C::Or[
          Nanoc::Core::Item,
          Nanoc::Core::Layout,
          Nanoc::Core::Configuration,
          Nanoc::Core::IdentifiableCollection,
        ]

      C_RAW_CONTENT =
        C::Or[
          C::ArrayOf[C::Or[String, Regexp]],
          C::Bool,
        ]

      C_ATTR =
        C::Or[
          C::ArrayOf[Symbol],
          C::HashOf[Symbol => C::Any],
          C::Bool,
        ]

      C_ARGS =
        C::KeywordArgs[
          raw_content: C::Optional[C_RAW_CONTENT],
          attributes: C::Optional[C_ATTR],
          compiled_content: C::Optional[C::Bool],
          path: C::Optional[C::Bool],
        ]

      attr_reader :dependency_store
      attr_reader :root

      def initialize(dependency_store, root:)
        @dependency_store = dependency_store
        @root = root
      end

      contract C_OBJ, C_ARGS => C::Any
      def bounce(obj, raw_content: false, attributes: false, compiled_content: false, path: false)
        Nanoc::Core::NotificationCenter.post(:dependency_created, @root, obj)

        @dependency_store.record_dependency(
          @root,
          obj,
          raw_content:,
          attributes:,
          compiled_content:,
          path:,
        )
      end

      class Null < DependencyTracker
        include Nanoc::Core::ContractsSupport

        def initialize; end

        contract C_OBJ, C_ARGS => C::Any
        def bounce(_obj, raw_content: false, attributes: false, compiled_content: false, path: false); end
      end
    end
  end
end
