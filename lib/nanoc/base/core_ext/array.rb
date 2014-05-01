# encoding: utf-8

module Nanoc::ArrayExtensions

  # Returns a new array where all items' keys are recursively converted to
  # symbols by calling {Nanoc::ArrayExtensions#symbolize_keys_recursively} or
  # {Nanoc::HashExtensions#symbolize_keys_recursively}.
  #
  # @return [Array] The converted array
  def symbolize_keys_recursively
    array = []
    each do |element|
      array << (element.respond_to?(:symbolize_keys_recursively) ? element.symbolize_keys_recursively : element)
    end
    array
  end

  # @deprecated Renamed to {#symbolize_keys_recursively}
  def symbolize_keys
    symbolize_keys_recursively
  end

  # Returns a new array where all items' keys are recursively converted to
  # strings by calling {Nanoc::ArrayExtensions#stringify_keys_recursively} or
  # {Nanoc::HashExtensions#stringify_keys_recursively}.
  #
  # @return [Array] The converted array
  def stringify_keys_recursively
    reduce([]) do |array, element|
      array + [ element.respond_to?(:stringify_keys_recursively) ? element.stringify_keys_recursively : element ]
    end
  end

  # @deprecated Renamed to {#stringify_keys_recursively}
  def stringify_keys
    stringify_keys_recursively
  end

  # Freezes the contents of the array, as well as all array elements. The
  # array elements will be frozen using {#freeze_recursively} if they respond
  # to that message, or #freeze if they do not.
  #
  # @see Hash#freeze_recursively
  #
  # @return [void]
  #
  # @since 3.2.0
  def freeze_recursively
    return if self.frozen?
    freeze
    each do |value|
      if value.respond_to?(:freeze_recursively)
        value.freeze_recursively
      else
        value.freeze
      end
    end
  end

  # Calculates the checksum for this array. Any change to this array will
  # result in a different checksum.
  #
  # @return [String] The checksum for this array
  #
  # @api private
  def checksum
    Nanoc::Checksummer.calc(self)
  end

end

class Array
  include Nanoc::ArrayExtensions
end
