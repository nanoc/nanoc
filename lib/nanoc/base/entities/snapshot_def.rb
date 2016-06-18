module Nanoc
  module Int
    class SnapshotDef
      include Nanoc::Int::ContractsSupport

      attr_reader :name

      contract Symbol, C::Bool => C::Any
      def initialize(name, is_final)
        @name = name
        @is_final = is_final
      end

      contract C::None => C::Bool
      def final?
        @is_final
      end
    end
  end
end
