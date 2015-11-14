module Nanoc
  # @api private
  class ViewContext
    attr_reader :reps
    attr_reader :items

    def initialize(reps:, items:)
      @reps = reps
      @items = items
    end
  end
end
