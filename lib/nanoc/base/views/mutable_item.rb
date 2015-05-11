# encoding: utf-8

module Nanoc
  class MutableItemView < Nanoc::ItemView
    # Sets the value for the given attribute.
    #
    # @param [Symbol] key
    #
    # @see Hash#[]=
    def []=(key, value)
      unwrap[key] = value
    end

    # Updates the attributes based on the given hash.
    #
    # @param [Hash] hash
    #
    # @return [self]
    def update_attributes(hash)
      hash.each { |k, v| unwrap[k] = v }
      self
    end
  end
end
