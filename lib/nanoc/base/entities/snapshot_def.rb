module Nanoc
  module Int
    class SnapshotDef
      include Contracts::Core

      C = Contracts

      attr_reader :name

      Contract Symbol, C::Bool => C::Any
      def initialize(name, is_final)
        @name = name
        @is_final = is_final
      end

      Contract C::None => C::Bool
      def final?
        @is_final
      end
    end
  end
end
