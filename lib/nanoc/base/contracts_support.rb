module Nanoc::Int
  # @api private
  module ContractsSupport
    def self.included(base)
      return if base.include?(::Contracts::Core)

      base.include(::Contracts::Core)
      base.extend(self)
      base.const_set('C', ::Contracts)
    end

    def contract(*args)
      return unless ENV['CONTRACTS'] || $CONTRACTS
      Contract(*args)
    end
  end
end
