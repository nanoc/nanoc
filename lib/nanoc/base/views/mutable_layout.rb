# encoding: utf-8

module Nanoc
  class MutableLayoutView < Nanoc::LayoutView
    def []=(key, value)
      unwrap[key] = value
    end
  end
end
