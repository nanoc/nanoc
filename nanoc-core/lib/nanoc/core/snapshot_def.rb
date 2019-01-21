# frozen_string_literal: true

module Nanoc
  module Core
    class SnapshotDef
      include Nanoc::Core::ContractsSupport

      attr_reader :name
      attr_reader :binary

      contract Symbol, C::KeywordArgs[binary: C::Optional[C::Bool]] => C::Any
      def initialize(name, binary:)
        @name = name
        @binary = binary
      end

      def binary?
        @binary
      end
    end
  end
end
