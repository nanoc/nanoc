require 'singleton'

module Nanoc::Int
  # @api private
  module ContractsSupport
    class Ignorer
      include Singleton

      # rubocop:disable Style/MethodMissing
      def method_missing(*_args)
        self
      end
      # rubocop:enable Style/MethodMissing

      def respond_to_missing?(*_args)
        true
      end
    end

    module DisabledContracts
      Any         = Ignorer.instance
      Bool        = Ignorer.instance
      Num         = Ignorer.instance
      KeywordArgs = Ignorer.instance
      Optional    = Ignorer.instance
      Maybe       = Ignorer.instance
      None        = Ignorer.instance
      ArrayOf     = Ignorer.instance
      Or          = Ignorer.instance
      Func        = Ignorer.instance
      RespondTo   = Ignorer.instance

      def contract(*args); end
    end

    module EnabledContracts
      def contract(*args)
        Contract(*args)
      end
    end

    def self.included(base)
      contracts_loadable =
        begin
          require 'contracts'
          true
        rescue LoadError
          false
        end

      should_enable = contracts_loadable && !ENV.key?('DISABLE_CONTRACTS')

      if should_enable
        unless base.include?(::Contracts::Core)
          base.include(::Contracts::Core)
          base.extend(EnabledContracts)
          base.const_set('C', ::Contracts)
        end
      else
        base.extend(DisabledContracts)
        base.const_set('C', DisabledContracts)
      end
    end
  end
end
