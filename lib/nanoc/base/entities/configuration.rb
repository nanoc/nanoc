# encoding: utf-8

module Nanoc

  # Represents the site configuration.
  class Configuration < ::Hash

    # Creates a new configuration with the given hash.
    #
    # @param [Hash] hash The actual configuration hash
    def initialize(hash)
      self.replace(hash)
    end

    # Returns an object that can be used for uniquely identifying objects.
    #
    # @return [Object] An unique reference to this object
    def reference
      :config
    end

  end

end
