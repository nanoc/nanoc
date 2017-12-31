# frozen_string_literal: true

module Nanoc::RuleDSL
  class CompilationRule
    include Nanoc::Int::ContractsSupport

    contract C::None => Symbol
    attr_reader :rep_name

    contract C::None => Nanoc::Int::Pattern
    attr_reader :pattern

    contract Nanoc::Int::Pattern, Symbol, Proc => C::Any
    def initialize(pattern, rep_name, block)
      @pattern = pattern
      @rep_name = rep_name.to_sym
      @block = block
    end

    contract Nanoc::Int::Item => C::Bool
    def applicable_to?(item)
      @pattern.match?(item.identifier)
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[
      site: Nanoc::Int::Site,
      recorder: Nanoc::RuleDSL::ActionRecorder,
      view_context: Nanoc::ViewContextForPreCompilation,
    ] => C::Any
    def apply_to(rep, site:, recorder:, view_context:)
      context = Nanoc::RuleDSL::CompilationRuleContext.new(
        rep: rep,
        recorder: recorder,
        site: site,
        view_context: view_context,
      )

      context.instance_exec(matches(rep.item.identifier), &@block)
    end

    # @api private
    contract Nanoc::Identifier => C::Or[nil, C::ArrayOf[String]]
    def matches(identifier)
      @pattern.captures(identifier)
    end
  end
end
