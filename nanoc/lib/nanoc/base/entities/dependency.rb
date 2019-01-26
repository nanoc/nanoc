# frozen_string_literal: true

module Nanoc
  module Int
    # @api private
    # A dependency between two items/layouts.
    class Dependency
      include Nanoc::Core::ContractsSupport

      C_OBJ_FROM = C::Or[Nanoc::Core::Item, Nanoc::Core::Layout, Nanoc::Core::Configuration, Nanoc::Core::IdentifiableCollection]
      C_OBJ_TO   = Nanoc::Core::Item

      contract C::None => C::Maybe[C_OBJ_FROM]
      attr_reader :from

      contract C::None => C::Maybe[C_OBJ_TO]
      attr_reader :to

      contract C::None => Nanoc::Int::Props
      attr_reader :props

      contract C::Maybe[C_OBJ_FROM], C::Maybe[C_OBJ_TO], Nanoc::Int::Props => C::Any
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
end
