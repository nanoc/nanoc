module Nanoc
  class View
    # @api private
    def initialize(context)
      @context = context
    end

    def _context
      @context
    end
  end
end
