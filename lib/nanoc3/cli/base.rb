# encoding: utf-8

module Nanoc3::CLI

  # @todo Remove me
  class Base

    # @return [Boolean] true if debug output is enabled, false if not
    #
    # @since 3.2.0
    attr_accessor :debug
    alias_method :debug?, :debug

    def initialize
      @debug = false
    end

  end

end
