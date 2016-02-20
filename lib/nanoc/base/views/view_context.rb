module Nanoc
  # @api private
  class ViewContext
    attr_reader :reps
    attr_reader :items
    attr_reader :dependency_tracker
    attr_reader :compiler

    def initialize(reps:, items:, dependency_tracker:, compiler:)
      @reps = reps
      @items = items
      @dependency_tracker = dependency_tracker
      @compiler = compiler
    end
  end
end
