# frozen_string_literal: true

module Nanoc
  module Core
    class CompilationItemRepView < ::Nanoc::Core::BasicItemRepView
      # @abstract
      def item_view_class
        Nanoc::Core::CompilationItemView
      end

      # Returns the item rep’s raw path. It includes the path to the output
      # directory and the full filename.
      #
      # @param [Symbol] snapshot The snapshot for which the path should be
      #   returned.
      #
      # @return [String] The item rep’s raw path.
      def raw_path(snapshot: :last)
        @context.dependency_tracker.bounce(_unwrap.item, compiled_content: true)

        raw_path = @item_rep.raw_path(snapshot:)

        unless @item_rep.compiled?
          could_load = _try_load_from_cache

          unless could_load
            raise Nanoc::Core::Errors::UnmetDependency.new(@item_rep, snapshot)
          end
        end

        # Ensure file exists
        if raw_path && !File.file?(raw_path)
          raise Nanoc::Core::Errors::InternalInconsistency,
                "File `#{raw_path}` expected to exist, but did not."
        end

        raw_path
      end

      # Returns the compiled content.
      #
      # @param [String] snapshot The name of the snapshot from which to
      #   fetch the compiled content. By default, the returned compiled content
      #   will be the content compiled right before the first layout call (if
      #   any).
      #
      # @return [String] The content at the given snapshot.
      def compiled_content(snapshot: nil)
        compiled_content_repo = @context.compiled_content_repo

        @context.dependency_tracker.bounce(@item_rep.item, compiled_content: true)

        begin
          compiled_content_repo.compiled_content(rep: @item_rep, snapshot:)
        rescue Nanoc::Core::Errors::UnmetDependency => e
          could_load = _try_load_from_cache
          unless could_load
            raise e
          end

          # Get the compiled content again. Previously in this method, this is
          # what raised the `UnmetDependency` error.
          compiled_content_repo.compiled_content(rep: @item_rep, snapshot:)
        end
      end

      def _try_load_from_cache
        # If we get an unmet dependency, try to load the content from the
        # compiled content cache. If this is not possible, re-raise the unmet
        # dependency error, and then let the compiler deal with it regularly.

        compilation_context = @context.compilation_context
        compiled_content_cache = compilation_context.compiled_content_cache
        compiled_content_repo = compilation_context.compiled_content_repo

        # Requirement: The item rep must not be marked as outdated.
        outdated = compilation_context.outdatedness_store.include?(@item_rep)
        return false if outdated

        # Requirement: The compiled content cache must have a cache entry for this item rep.
        cache_available = compiled_content_cache.full_cache_available?(@item_rep)
        return false unless cache_available

        # Load the compiled content from the cache
        Nanoc::Core::NotificationCenter.post(:cached_content_used, @item_rep)
        compiled_content_repo.set_all(@item_rep, compiled_content_cache[@item_rep])

        # Mark as compiled
        @item_rep.compiled = true

        true
      end
    end
  end
end
