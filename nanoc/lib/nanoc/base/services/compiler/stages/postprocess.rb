# frozen_string_literal: true

module Nanoc::Int::Compiler::Stages
  class Postprocess < Nanoc::Int::Compiler::Stage
    include Nanoc::Int::ContractsSupport

    def initialize(action_provider:, site:)
      @action_provider = action_provider
      @site = site
    end

    contract Nanoc::Int::Compiler => C::Any
    def run(compiler)
      @action_provider.postprocess(@site, compiler)
    end
  end
end
