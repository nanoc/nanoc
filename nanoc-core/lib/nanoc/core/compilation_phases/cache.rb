# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      # Provides functionality for (re)calculating the content of an item rep, with caching or
      # outdatedness checking. Delegates to s::Recalculate if outdated or no cache available.
      class Cache < Abstract
        include Nanoc::Core::ContractsSupport

        def initialize(wrapped:, compiled_content_cache:, compiled_content_store:)
          super(wrapped:)

          @compiled_content_cache = compiled_content_cache
          @compiled_content_store = compiled_content_store
        end

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(rep, is_outdated:)
          if can_reuse_content_for_rep?(rep, is_outdated:)
            # If cached content can be used for this item rep, do so, and skip
            # recalculation of the item rep compiled content.
            Nanoc::Core::NotificationCenter.post(:cached_content_used, rep)
            @compiled_content_store.set_all(rep, @compiled_content_cache[rep])
          else
            # Cached content couldn’t be used for this rep. Continue as usual with
            # recalculation of the item rep compiled content.
            yield

            # Update compiled content cache, now that the item rep is compiled.
            @compiled_content_cache[rep] = @compiled_content_store.get_all(rep)
          end

          rep.compiled = true
        end

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Bool
        def can_reuse_content_for_rep?(rep, is_outdated:)
          if is_outdated
            false
          else
            @compiled_content_cache.full_cache_available?(rep)
          end
        end
      end
    end
  end
end
