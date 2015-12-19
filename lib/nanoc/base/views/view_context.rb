module Nanoc
  # @api private
  class ViewContext
    attr_reader :reps
    attr_reader :items
    attr_reader :dependency_tracker

    # TODO: make dependency_tracker mandatory
    def initialize(reps:, items:, dependency_tracker: nil)
      @reps = reps
      @items = items
      @dependency_tracker = dependency_tracker
    end
  end
end
