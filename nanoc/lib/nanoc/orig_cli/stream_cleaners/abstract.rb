# frozen_string_literal: true

module Nanoc::OrigCLI::StreamCleaners
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
    # @param [String] str The string to clean
    #
    # @return [String] The cleaned string
    def clean(str) # rubocop:disable Lint/UnusedMethodArgument
      raise NotImplementedError, 'Subclasses of Nanoc::OrigCLI::StreamCleaners::Abstract must implement #clean'
    end
  end
end
