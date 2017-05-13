# frozen_string_literal: true

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
      Named       = Ignorer.instance
      IterOf      = Ignorer.instance
      HashOf      = Ignorer.instance

      def contract(*args); end
    end

    module EnabledContracts
      class AbstractContract
        def self.[](*vals)
          new(*vals)
        end
      end

      class Named < AbstractContract
        def initialize(name)
          @name = name
        end

        def valid?(val)
          val.is_a?(Kernel.const_get(@name))
        end

        def inspect
          "#{self.class}(#{@name})"
        end
      end

      class IterOf < AbstractContract
        def initialize(contract)
          @contract = contract
        end

        def valid?(val)
          val.respond_to?(:each) && val.all? { |v| Contract.valid?(v, @contract) }
        end

        def inspect
          "#{self.class}(#{@contract})"
        end
      end

      def contract(*args)
        Contract(*args)
      end
    end

    def self.setup_once
      @_contracts_support__setup ||= false
      return @_contracts_support__should_enable if @_contracts_support__setup
      @_contracts_support__setup = true

      contracts_loadable =
        begin
          require 'contracts'
          true
        rescue LoadError
          false
        end

      @_contracts_support__should_enable = contracts_loadable && !ENV.key?('DISABLE_CONTRACTS')

      if @_contracts_support__should_enable
        # FIXME: ugly
        ::Contracts.const_set('Named', EnabledContracts::Named)
        ::Contracts.const_set('IterOf', EnabledContracts::IterOf)
      end

      @_contracts_support__should_enable
    end

    def self.included(base)
      should_enable = setup_once

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
