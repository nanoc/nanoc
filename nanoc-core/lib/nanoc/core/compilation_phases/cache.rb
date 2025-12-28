# frozen_string_literal: true

module Nanoc
  module Core
    module CompilationPhases
      # Stores the compiled content in the cache once available.
      class Cache < Abstract
        include Nanoc::Core::ContractsSupport

        def initialize(wrapped:, compiled_content_cache:, compiled_content_repo:)
          super(wrapped:)

          @compiled_content_cache = compiled_content_cache
          @compiled_content_repo = compiled_content_repo
        end

        contract Nanoc::Core::ItemRep, C::KeywordArgs[is_outdated: C::Bool], C::Func[C::None => C::Any] => C::Any
        def run(rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
          return if rep.compiled?

          yield
          @compiled_content_cache[rep] = @compiled_content_repo.get_all(rep)
          rep.compiled = true
        end
      end
    end
  end
end
