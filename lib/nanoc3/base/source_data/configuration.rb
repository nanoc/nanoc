# encoding: utf-8

module Nanoc3

  # TODO document
  class Configuration < ::Hash

    # TODO document
    def initialize(hash)
      self.replace(hash)
    end

    # TODO document
    def reference
      :config
    end

  end

end
