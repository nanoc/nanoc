# encoding: utf-8

module Nanoc
  class ConfigView
    # @api private
    def initialize(config)
      @config = config
    end

    # @api private
    def unwrap
      @config
    end

    def [](key)
      @config[key]
    end
  end
end
