# frozen_string_literal: true

module Nanoc
  module Base
    class View
      include Nanoc::Core::ContractsSupport

      # @api private
      # TODO: disallow nil
      contract C::Maybe[C::Or[
        Nanoc::Core::ViewContextForCompilation,
        Nanoc::Core::ViewContextForPreCompilation,
        Nanoc::Core::ViewContextForShell
      ]] => C::Any
      def initialize(context)
        @context = context
      end

      # @api private
      def _context
        @context
      end

      # @api private
      def _unwrap
        raise NotImplementedError
      end

      # True if the wrapped object is frozen; false otherwise.
      #
      # @return [Boolean]
      #
      # @see Object#frozen?
      def frozen?
        _unwrap.frozen?
      end

      def inspect
        "<#{self.class}>"
      end
    end
  end
end
