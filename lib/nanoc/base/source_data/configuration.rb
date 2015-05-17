# encoding: utf-8

module Nanoc::Int
  # Represents the site configuration.
  #
  # @api private
  class Configuration < ::Nanoc::Int::Attributes
    # Returns an object that can be used for uniquely identifying objects.
    #
    # @return [Object] An unique reference to this object
    def reference
      :config
    end

    def __nanoc_checksum
      @hash.__nanoc_checksum
    end
  end
end
