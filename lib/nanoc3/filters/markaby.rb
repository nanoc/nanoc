# encoding: utf-8

module Nanoc3::Filters
  class Markaby < Nanoc3::Filter

    # Runs the content through [Markaby](http://markaby.rubyforge.org/).
    # This method takes no options.
    #
    # @param [String] content The content to filter
    #
    # @return [String] The filtered content
    def run(content, params={})
      require 'markaby'

      # Get result
      ::Markaby::Builder.new(assigns).instance_eval(content).to_s
    end

  end
end
