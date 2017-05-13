# frozen_string_literal: true

module Nanoc::Int
  # @api private
  # A dependency between two items/layouts.
  class Dependency
    include Nanoc::Int::ContractsSupport

    contract C::None => C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]]
    attr_reader :from

    contract C::None => C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]]
    attr_reader :to

    contract C::None => Nanoc::Int::Props
    attr_reader :props

    contract C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]], C::Maybe[C::Or[Nanoc::Int::Item, Nanoc::Int::Layout]], Nanoc::Int::Props => C::Any
    def initialize(from, to, props)
      @from  = from
      @to    = to
      @props = props
    end

    contract C::None => String
    def inspect
      "Dependency(#{@from.inspect} -> #{@to.inspect}, #{@props.inspect})"
    end
  end
end
