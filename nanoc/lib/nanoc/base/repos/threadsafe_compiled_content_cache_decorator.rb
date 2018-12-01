# frozen_string_literal: true

module Nanoc
  module Int
    # Wraps a compiled content cache and makes it thread-safe.
    #
    # @api private
    class ThreadsafeCompiledContentCacheDecorator
      include Nanoc::Core::ContractsSupport

      def initialize(cache)
        @cache = cache
        @mutex = Mutex.new
      end

      contract Nanoc::Core::ItemRep => C::Maybe[C::HashOf[Symbol => Nanoc::Core::Content]]
      def [](rep)
        @mutex.synchronize do
          @cache[rep]
        end
      end

      contract Nanoc::Core::ItemRep, C::HashOf[Symbol => Nanoc::Core::Content] => C::Any
      def []=(rep, content)
        @mutex.synchronize do
          @cache[rep] = content
        end
      end

      def prune(*args)
        # NOTE: No need to synchronize, as this is done when compilation has been completed, and is done on the main thread.
        @cache.prune(*args)
      end

      def full_cache_available?(rep)
        @mutex.synchronize do
          @cache.full_cache_available?(rep)
        end
      end

      def load(*args)
        @cache.load(*args)
      end

      def store(*args)
        @cache.store(*args)
      end
    end
  end
end
