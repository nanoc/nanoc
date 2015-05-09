# encoding: utf-8

module Nanoc
  class MutableConfigView < Nanoc::ConfigView
    def []=(key, value)
      @config[key] = value
    end
  end
end
