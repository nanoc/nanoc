module Nanoc
  module Int
    class SnapshotDef
      attr_reader :name

      def initialize(name, is_final)
        @name = name
        @is_final = is_final
      end

      def final?
        @is_final
      end
    end
  end
end
