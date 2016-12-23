module Nanoc
  # @api private
  class ViewContext
    attr_reader :reps
    attr_reader :items
    attr_reader :dependency_tracker
    attr_reader :compilation_context

    def initialize(reps:, items:, dependency_tracker:, compilation_context:)
      @reps = reps
      @items = items
      @dependency_tracker = dependency_tracker
      @compilation_context = compilation_context
    end
  end
end
