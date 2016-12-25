module Nanoc
  module Int
    class SnapshotDef
      include Nanoc::Int::ContractsSupport

      attr_reader :name

      contract Symbol => C::Any
      def initialize(name)
        @name = name
      end
    end
  end
end
