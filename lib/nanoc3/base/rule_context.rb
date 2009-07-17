module Nanoc3

  # Nanoc3::RuleContext provides a context in which compilation and routing
  # rules can be executed. It provides access to the item representation that
  # is being compiled or routed.
  class RuleContext

    # Creates a new rule context for the given item representation.
    def initialize(rep)
      @rep = rep
    end

    # Returns the item representation that is currently being processed in
    # this context.
    attr_reader :rep

  end

end
