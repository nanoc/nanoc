# encoding: utf-8

module Nanoc
  class MutableItemView < Nanoc::ItemView
    def []=(key, value)
      unwrap[key] = value
    end

    def update_attributes(hash)
      hash.each { |k, v| unwrap[k] = v }
    end
  end
end
