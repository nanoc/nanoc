# frozen_string_literal: true

module Nanoc::CLI::StreamCleaners
  # Superclass for all stream cleaners. Stream cleaners have a single method,
  # {#clean}, that takes a string and returns a cleaned string. Stream cleaners
  # can have state, so they can act as a FSM.
  #
  # @abstract Subclasses must implement {#clean}
  #
  # @api private
  class Abstract
    # Returns a cleaned version of the given string.
    #
    # @param [String] s The string to clean
    #
    # @return [String] The cleaned string
    def clean(s) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError, 'Subclasses of Nanoc::CLI::StreamCleaners::Abstract must implement #clean'
    end
  end
end
