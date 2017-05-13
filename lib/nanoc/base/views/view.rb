# frozen_string_literal: true

module Nanoc
  class View
    # @api private
    def initialize(context)
      @context = context
    end

    # @api private
    def _context
      @context
    end

    # @api private
    def unwrap
      raise NotImplementedError
    end

    # True if the wrapped object is frozen; false otherwise.
    #
    # @return [Boolean]
    #
    # @see Object#frozen?
    def frozen?
      unwrap.frozen?
    end

    def inspect
      "<#{self.class}>"
    end
  end
end
