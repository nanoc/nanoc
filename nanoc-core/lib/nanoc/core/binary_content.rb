# frozen_string_literal: true

module Nanoc
  module Core
    class BinaryContent < Content
      contract C::None => C::Bool
      def binary?
        true
      end
    end
  end
end
