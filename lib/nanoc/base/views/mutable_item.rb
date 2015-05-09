# encoding: utf-8

module Nanoc
  class MutableItemView < Nanoc::ItemView
    def []=(key, value)
      unwrap[key] = value
    end
  end
end
