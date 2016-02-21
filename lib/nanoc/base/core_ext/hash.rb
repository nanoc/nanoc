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

  def __nanoc_make_immutable_and_symbolize_keys_recursively
    inject(::Hamster::Hash.new) do |memo, (key, value)|
      new_key   = key.respond_to?(:to_sym) ? key.to_sym : key
      new_value = value.respond_to?(:__nanoc_make_immutable_and_symbolize_keys_recursively) ? value.__nanoc_make_immutable_and_symbolize_keys_recursively : value
      memo.put(new_key, new_value)
    end
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
    return if frozen? && !is_a?(Hamster::Hash)
    freeze
    each_pair do |_key, value|
      if value.respond_to?(:__nanoc_freeze_recursively)
        value.__nanoc_freeze_recursively
      else
        value.freeze
      end
    end
  end
end

# @api private
class Hash
  include Nanoc::HashExtensions
end

# @api private
class ::Hamster::Hash
  include Nanoc::HashExtensions
end
