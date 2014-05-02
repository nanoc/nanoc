# encoding: utf-8

module Nanoc::HashExtensions

  # Returns a new hash where all keys are recursively converted to symbols by
  # calling {Nanoc::ArrayExtensions#symbolize_keys_recursively} or
  # {Nanoc::HashExtensions#symbolize_keys_recursively}.
  #
  # @return [Hash] The converted hash
  def symbolize_keys_recursively
    hash = {}
    each_pair do |key, value|
      new_key   = key.respond_to?(:to_sym) ? key.to_sym : key
      new_value = value.respond_to?(:symbolize_keys_recursively) ? value.symbolize_keys_recursively : value
      hash[new_key] = new_value
    end
    hash
  end

  # @deprecated Renamed to {#symbolize_keys_recursively}
  def symbolize_keys
    symbolize_keys_recursively
  end

  # Returns a new hash where all keys are recursively converted to strings by
  # calling {Nanoc::ArrayExtensions#stringify_keys_recursively} or
  # {Nanoc::HashExtensions#stringify_keys_recursively}.
  #
  # @return [Hash] The converted hash
  def stringify_keys_recursively
    reduce({}) do |hash, (key, value)|
      hash.merge(key.to_s => value.respond_to?(:stringify_keys_recursively) ? value.stringify_keys_recursively : value)
    end
  end

  # @deprecated Renamed to {#stringify_keys_recursively}
  def stringify_keys
    stringify_keys_recursively
  end

  # Freezes the contents of the hash, as well as all hash values. The hash
  # values will be frozen using {#freeze_recursively} if they respond to
  # that message, or #freeze if they do not.
  #
  # @see Array#freeze_recursively
  #
  # @return [void]
  #
  # @since 3.2.0
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
    Nanoc::Checksummer.calc(self)
  end

end

class Hash
  include Nanoc::HashExtensions
end
