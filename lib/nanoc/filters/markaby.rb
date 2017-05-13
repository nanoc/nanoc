# frozen_string_literal: true

module Nanoc::Filters
  # @api private
  class Markaby < Nanoc::Filter
    identifier :markaby

    requires 'markaby'

    # Runs the content through [Markaby](http://markaby.github.io/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, _params = {})
      # Get result
      ::Markaby::Builder.new(assigns).instance_eval(content).to_s
    end
  end
end
