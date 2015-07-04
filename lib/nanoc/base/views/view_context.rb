module Nanoc
  # @api private
  class ViewContext
    attr_reader :reps

    def initialize(reps:)
      @reps = reps
    end
  end
end
