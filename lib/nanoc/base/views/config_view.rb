# frozen_string_literal: true

module Nanoc
  class ConfigView < ::Nanoc::View
    # @api private
    NONE = Object.new.freeze

    # @api private
    def initialize(config, context)
      super(context)
      @config = config
    end

    # @api private
    def unwrap
      @config
    end

    # @see Hash#fetch
    def fetch(key, fallback = NONE, &_block)
      @context.dependency_tracker.bounce(unwrap, attributes: [key])
      @config.fetch(key) do
        if !fallback.equal?(NONE)
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
      @context.dependency_tracker.bounce(unwrap, attributes: [key])
      @config.key?(key)
    end

    # @see Hash#[]
    def [](key)
      @context.dependency_tracker.bounce(unwrap, attributes: [key])
      @config[key]
    end

    # @see Hash#each
    def each(&block)
      @context.dependency_tracker.bounce(unwrap, attributes: true)
      @config.each(&block)
    end
  end
end
