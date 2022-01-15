# frozen_string_literal: true

module Nanoc
  module Core
    class LayoutCollection < IdentifiableCollection
      prepend MemoWise

      def initialize(config, objects = [])
        initialize_basic(config, objects, 'layouts')
      end

      # contract C::Any => C::Maybe[C::RespondTo[:identifier]]
      def get_memoized(arg)
        get_unmemoized(arg)
      end
      memo_wise :get_memoized

      def reference
        'layouts'
      end
    end
  end
end
