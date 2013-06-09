# encoding: utf-8

module Nanoc::HashExtensions

  # Returns a new hash where all keys are recursively converted to symbols by
  # calling {Nanoc::ArrayExtensions#symbolize_keys_recursively} or
  # {Nanoc::HashExtensions#symbolize_keys_recursively}.
  #
  # @return [Hash] The converted hash
  def symbolize_keys_recursively
    hash = {}
    self.each_pair do |key, value|
      new_key   = key.respond_to?(:to_sym) ? key.to_sym : key
      new_value = value.respond_to?(:symbolize_keys_recursively) ? value.symbolize_keys_recursively : value
      hash[new_key] = new_value
    end
    hash
  end

  # Returns a new hash where all keys are recursively converted to strings by
  # calling {Nanoc::ArrayExtensions#stringify_keys_recursively} or
  # {Nanoc::HashExtensions#stringify_keys_recursively}.
  #
  # @return [Hash] The converted hash
  def stringify_keys_recursively
    inject({}) do |hash, (key, value)|
      hash.merge(key.to_s => value.respond_to?(:stringify_keys_recursively) ? value.stringify_keys_recursively : value)
    end
  end

  # Freezes the contents of the hash, as well as all hash values. The hash
  # values will be frozen using {#freeze_recursively} if they respond to
  # that message, or #freeze if they do not.
  #
  # @see Array#freeze_recursively
  #
  # @return [void]
  def freeze_recursively
    return if self.frozen?
    freeze
    each_pair do |key, value|
      if value.respond_to?(:freeze_recursively)
        value.freeze_recursively
      else
        value.freeze
      end
    end
  end

  # Calculates the checksum for this hash. Any change to this hash will result
  # in a different checksum.
  #
  # @return [String] The checksum for this hash
  #
  # @api private
  def checksum
    array = self.to_a.sort_by { |kv| kv[0].to_s }
    array.checksum
  end

end

class Hash
  include Nanoc::HashExtensions
end
