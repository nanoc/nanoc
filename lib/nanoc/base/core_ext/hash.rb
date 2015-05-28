# @api private
module Nanoc::HashExtensions
  # Returns a new hash where all keys are recursively converted to symbols by
  # calling {Nanoc::ArrayExtensions#__nanoc_symbolize_keys_recursively} or
  # {Nanoc::HashExtensions#__nanoc_symbolize_keys_recursively}.
  #
  # @return [Hash] The converted hash
  def __nanoc_symbolize_keys_recursively
    hash = {}
    each_pair do |key, value|
      new_key   = key.respond_to?(:to_sym) ? key.to_sym : key
      new_value = value.respond_to?(:__nanoc_symbolize_keys_recursively) ? value.__nanoc_symbolize_keys_recursively : value
      hash[new_key] = new_value
    end
    hash
  end

  # Freezes the contents of the hash, as well as all hash values. The hash
  # values will be frozen using {#__nanoc_freeze_recursively} if they respond to
  # that message, or #freeze if they do not.
  #
  # @see Array#__nanoc_freeze_recursively
  #
  # @return [void]
  #
  # @since 3.2.0
  def __nanoc_freeze_recursively
    return if self.frozen?
    freeze
    each_pair do |_key, value|
      if value.respond_to?(:__nanoc_freeze_recursively)
        value.__nanoc_freeze_recursively
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
  def __nanoc_checksum
    Nanoc::Int::Checksummer.calc(self)
  end
end

# @api private
class Hash
  include Nanoc::HashExtensions
end
