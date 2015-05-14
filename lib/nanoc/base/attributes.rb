# encoding: utf-8

module Nanoc::Int
  class Attributes
    # @api private
    NONE = Object.new

    def initialize(hash)
      @hash = hash.each_with_object({}) do |(k, v), memo|
        memo[k.to_s] = v
      end
    end

    def [](key)
      res = @hash[key.to_s]
      res
      # FIXME: following is not tested
      # if res.is_a?(Hash)
      #   res = Nanoc::Int::Attributes.new(res)
      #   # FIXME: following is not tested
      #   res.__nanoc_freeze_recursively if frozen?
      #   res
      # else
      #   res
      # end
    end

    def []=(key, value)
      @hash[key.to_s] = value
    end

    def fetch(key, fallback=NONE, &block)
      if key?(key)
        self[key]
      else
        if !fallback.equal?(NONE)
          fallback
        elsif block_given?
          yield(key)
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end
    end

    def key?(key)
      @hash.key?(key.to_s)
    end

    def has_key?(key)
      key?(key)
    end

    def merge!(other)
      other.each do |k, v|
        @hash[k.to_s] = v
      end
      self
    end

    def update(other)
      merge!(other)
    end

    def merge(other)
      self.dup.merge!(other)
    end

    def delete(key)
      @hash.delete(key.to_s)
    end

    # Required for Mustache :(
    def to_hash
      self
    end

    def __nanoc_freeze_recursively
      @hash.__nanoc_freeze_recursively
    end
  end
end
