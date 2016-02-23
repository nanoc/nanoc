# @api private
module Nanoc::ArrayExtensions
  # Returns a new array where all items' keys are recursively converted to
  # symbols by calling {Nanoc::ArrayExtensions#__nanoc_symbolize_keys_recursively} or
  # {Nanoc::HashExtensions#__nanoc_symbolize_keys_recursively}.
  #
  # @return [Array] The converted array
  def __nanoc_symbolize_keys_recursively
    array = []
    each do |element|
      array << (element.respond_to?(:__nanoc_symbolize_keys_recursively) ? element.__nanoc_symbolize_keys_recursively : element)
    end
    array
  end

  def __nanoc_hamsterize
    reduce(Hamster::Vector.new) do |memo, elem|
      new_elem =
        if elem.respond_to?(:__nanoc_hamsterize)
          elem.__nanoc_hamsterize
        elsif elem.respond_to?(:__nanoc_freeze_recursively)
          elem.__nanoc_freeze_recursively
        else
          elem.freeze
        end

      memo.add(new_elem)
    end
  end

  # Freezes the contents of the array, as well as all array elements. The
  # array elements will be frozen using {#__nanoc_freeze_recursively} if they respond
  # to that message, or #freeze if they do not.
  #
  # @see Hash#__nanoc_freeze_recursively
  #
  # @return [void]
  #
  # @since 3.2.0
  def __nanoc_freeze_recursively
    return if frozen? && !is_a?(Hamster::Vector)
    freeze
    each do |value|
      if value.respond_to?(:__nanoc_freeze_recursively)
        value.__nanoc_freeze_recursively
      else
        value.freeze
      end
    end
  end
end

# @api private
class Array
  include Nanoc::ArrayExtensions
end

# @api private
class ::Hamster::Vector
  include Nanoc::ArrayExtensions
end
