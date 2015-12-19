module Nanoc
  # @api private
  class ViewContext
    attr_reader :reps
    attr_reader :items
    attr_reader :dependency_tracker

    def initialize(reps:, items:, dependency_tracker:)
      @reps = reps
      @items = items
      @dependency_tracker = dependency_tracker
    end
  end
end
