# frozen_string_literal: true

module Nanoc::RuleDSL
  class Rule
    include Nanoc::Core::ContractsSupport

    contract C::None => Symbol
    attr_reader :rep_name

    contract C::None => Nanoc::Core::Pattern
    attr_reader :pattern

    contract Nanoc::Core::Pattern, Symbol, Proc => C::Any
    def initialize(pattern, rep_name, block)
      @pattern = pattern
      @rep_name = rep_name.to_sym
      @block = block
    end

    contract Nanoc::Int::Item => C::Bool
    def applicable_to?(item)
      @pattern.match?(item.identifier)
    end

    # @api private
    contract Nanoc::Core::Identifier => C::Or[nil, C::ArrayOf[String]]
    def matches(identifier)
      @pattern.captures(identifier)
    end
  end
end
