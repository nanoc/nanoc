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
  end
end
