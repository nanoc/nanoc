# encoding: utf-8

module Nanoc::Int
  class Attributes
    def initialize(hash)
      @hash = hash.each_with_object({}) do |(k, v), memo|
        memo[k.to_s] = v
      end
    end

    def [](key)
      res = @hash[key.to_s]
      # FIXME: following is not tested
      if res.is_a?(Hash)
        Nanoc::Int::Attributes.new(res)
      else
        res
      end
    end

    def []=(key, value)
      @hash[key.to_s] = value
    end

    def key?(key)
      @hash.key?(key.to_s)
    end

    def merge!(other)
      other.each do |k, v|
        @hash[k.to_s] = v
      end
      self
    end

    def merge(other)
      self.dup.merge!(other)
    end

    def delete(key)
      @hash.delete(key.to_s)
    end

    # Required for Mustache :(
    def to_hash
      @hash
    end

    def __nanoc_freeze_recursively
      @hash.__nanoc_freeze_recursively
    end
  end
end
