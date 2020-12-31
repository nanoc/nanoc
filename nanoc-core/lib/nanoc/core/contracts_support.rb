# frozen_string_literal: true

module Nanoc
  module Core
    module ContractsSupport
      class Ignorer
        include Singleton

        def method_missing(*_args) # rubocop:disable Style/MethodMissingSuper
          self
        end

        def respond_to_missing?(*_args)
          true
        end
      end

      module DisabledContracts
        Any         = Ignorer.instance
        Bool        = Ignorer.instance
        Num         = Ignorer.instance
        KeywordArgs = Ignorer.instance
        Args        = Ignorer.instance
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
        AbsolutePathString = Ignorer.instance

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

        class AbsolutePathString < AbstractContract
          def self.valid?(val)
            val.is_a?(String) && Pathname.new(val).absolute?
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

        # FIXME: Do something better with contracts on Ruby 3.x
        @_contracts_support__should_enable = contracts_loadable && !RUBY_VERSION.start_with?('3') && !ENV.key?('DISABLE_CONTRACTS')

        if @_contracts_support__should_enable
          # FIXME: ugly
          ::Contracts.const_set('Named', EnabledContracts::Named)
          ::Contracts.const_set('IterOf', EnabledContracts::IterOf)
          ::Contracts.const_set('AbsolutePathString', EnabledContracts::AbsolutePathString)

          warn_about_performance
        end

        @_contracts_support__should_enable
      end

      def self.enabled?
        setup_once
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

      def self.warn_about_performance
        return if ENV.key?('CI')
        return if ENV.key?('NANOC_DEV_MODE')

        puts '-' * 78
        puts 'A NOTE ABOUT PERFORMANCE:'
        puts 'The `contracts` gem is loaded, which enables extra run-time checks, but can drastically reduce Nanoc’s performance. The `contracts` gem is intended for development purposes, and is not recommended for day-to-day Nanoc usage.'
        puts

        if defined?(Bundler)
          puts 'To speed up compilation, remove `contracts` from the Gemfile and run `bundle install`.'
        else
          puts 'To speed up compilation, either uninstall the `contracts` gem, or use Bundler (https://bundler.io/) with a Gemfile that doesn’t include `contracts`.'
        end

        puts '-' * 78
      end
    end
  end
end
