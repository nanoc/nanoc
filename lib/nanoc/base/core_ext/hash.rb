# encoding: utf-8

module Nanoc::HashExtensions

  # Returns a new hash where all keys are recursively converted to symbols by
  # calling {Nanoc::ArrayExtensions#symbolize_keys} or
  # {Nanoc::HashExtensions#symbolize_keys}.
  #
  # @return [Hash] The converted hash
  def symbolize_keys
    inject({}) do |hash, (key, value)|
      hash.merge(key.to_sym => value.respond_to?(:symbolize_keys) ? value.symbolize_keys : value)
    end
  end

  # Returns a new hash where all keys are recursively converted to strings by
  # calling {Nanoc::ArrayExtensions#stringify_keys} or
  # {Nanoc::HashExtensions#stringify_keys}.
  #
  # @return [Hash] The converted hash
  def stringify_keys
    inject({}) do |hash, (key, value)|
      hash.merge(key.to_s => value.respond_to?(:stringify_keys) ? value.stringify_keys : value)
    end
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
    array = self.to_a.sort_by { |kv| kv[0].to_s }
    array.checksum
  end

end

class Hash
  include Nanoc::HashExtensions
end
