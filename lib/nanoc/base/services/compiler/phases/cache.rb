module Nanoc::Int::Compiler::Phases
  # Provides functionality for (re)calculating the content of an item rep, with caching or
  # outdatedness checking. Delegates to s::Recalculate if outdated or no cache available.
  class Cache
    include Nanoc::Int::ContractsSupport

    def initialize(compiled_content_cache:, snapshot_repo:, wrapped:)
      @compiled_content_cache = compiled_content_cache
      @snapshot_repo = snapshot_repo
      @wrapped = wrapped
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Any
    def run(rep, is_outdated:)
      if can_reuse_content_for_rep?(rep, is_outdated: is_outdated)
        Nanoc::Int::NotificationCenter.post(:cached_content_used, rep)

        @snapshot_repo.set_all(rep, @compiled_content_cache[rep])
      else
        @wrapped.run(rep, is_outdated: is_outdated)
      end

      rep.compiled = true
      @compiled_content_cache[rep] = @snapshot_repo.get_all(rep)
    end

    contract Nanoc::Int::ItemRep, C::KeywordArgs[is_outdated: C::Bool] => C::Bool
    def can_reuse_content_for_rep?(rep, is_outdated:)
      !is_outdated && !@compiled_content_cache[rep].nil?
    end
  end
end
