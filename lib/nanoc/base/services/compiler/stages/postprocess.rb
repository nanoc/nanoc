# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class Postprocess
    include Nanoc::Int::ContractsSupport

    def initialize(action_provider:, site:, reps:)
      @action_provider = action_provider
      @site = site
      @reps = reps
    end

    contract Nanoc::Int::Compiler => C::Any
    def run(compiler)
      @action_provider.postprocess(@site, compiler, @reps)
    end
  end
end
