# encoding: utf-8

module Nanoc3::HashExtensions

  # Returns a new hash where all keys are recursively converted to symbols by
  # calling {Nanoc3::ArrayExtensions#symbolize_keys} or
  # {Nanoc3::HashExtensions#symbolize_keys}.
  #
  # @return [Hash] The converted hash
  def symbolize_keys
    inject({}) do |hash, (key, value)|
      hash.merge(key.to_sym => value.respond_to?(:symbolize_keys) ? value.symbolize_keys : value)
    end
  end

  # Returns a new hash where all keys are recursively converted to strings by
  # calling {Nanoc3::ArrayExtensions#stringify_keys} or
  # {Nanoc3::HashExtensions#stringify_keys}.
  #
  # @return [Hash] The converted hash
  def stringify_keys
    inject({}) do |hash, (key, value)|
      hash.merge(key.to_s => value.respond_to?(:stringify_keys) ? value.stringify_keys : value)
    end
  end

end

class Hash
  include Nanoc3::HashExtensions
end
