# frozen_string_literal: true

module Nanoc
  module Core
    class ConfigView < ::Nanoc::Core::View
      # @api private
      def initialize(config, context)
        super(context)
        @config = config
      end

      # @api private
      def _unwrap
        @config
      end

      # @api private
      def output_dir
        @config.output_dir
      end

      # @see Hash#fetch
      def fetch(key, fallback = Nanoc::Core::UNDEFINED, &)
        @context.dependency_tracker.bounce(_unwrap, attributes: [key])
        @config.fetch(key) do
          if !Nanoc::Core::UNDEFINED.equal?(fallback)
            fallback
          elsif block_given?
            yield(key)
          else
            raise KeyError, "key not found: #{key.inspect}"
          end
        end
      end

      # @see Hash#key?
      def key?(key)
        @context.dependency_tracker.bounce(_unwrap, attributes: [key])
        @config.key?(key)
      end

      # @see Hash#[]
      def [](key)
        @context.dependency_tracker.bounce(_unwrap, attributes: [key])
        @config[key]
      end

      # @see Hash#each
      def each(&)
        @context.dependency_tracker.bounce(_unwrap, attributes: true)
        @config.each(&)
      end

      # @see Configuration#env_name
      def env_name
        @context.dependency_tracker.bounce(_unwrap, attributes: true)
        @config.env_name
      end

      # @see Hash#dig
      def dig(*keys)
        @context.dependency_tracker.bounce(_unwrap, attributes: keys.take(1))
        @config.dig(*keys)
      end
    end
  end
end
